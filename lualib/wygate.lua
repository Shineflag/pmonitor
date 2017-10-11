--[[
* File:        wygate.lua
* Author:      shineflag
* Date :       2017-09-26 15:18:54
* Description: woyao socket server (实现对包头长度为4个字节socket的)
* History：
    v0.0.1 : first version(2016-01-11)
]]


local skynet = require "skynet"
local socketdriver = require "skynet.socketdriver"
local queue = require "skynet.queue"
local log = require "log"


local listenfd

local TAG = "WYGATE"
local wygate = {}  --api
local socket_pool = setmetatable( -- store all socket object
	{},
	{ __gc = function(p)
		for id,v in pairs(p) do
			socketdriver.close(id)
			-- don't need clear v.buffer, because buffer pool will be free at the end
			p[id] = nil
		end
	end
	}
)

local function wakeup(s)
	local co = s.co
	if co then
		s.co = nil
		skynet.wakeup(co)
	end
end

local function suspend(s)
	assert(not s.co)
	s.co = coroutine.running()
	skynet.wait(s.co)
	-- wakeup closing corouting every time suspend,
	-- because socket.close() will wait last socket buffer operation before clear the buffer.
	if s.closing then
		skynet.wakeup(s.closing)
	end
end

local function funcqueen( cs, func )
	cs(func)
end

local function connect(id, func)
	local s = {
		id = id,
		buffer = "",
		connected = false,
		connecting = true,
		co = false,
		callback = func,
		protocol = "TCP",
		cs = queue(),
	}
	assert(not socket_pool[id], "socket is not closed")
	socket_pool[id] = s
	suspend(s)
	local err = s.connecting
	s.connecting = nil
	if s.connected then
		return id
	else
		socket_pool[id] = nil
		return nil, err
	end
end


--主动连接一个端口
function wygate.open(addr, port)
	local id = socketdriver.connect(addr,port)
	return connect(id)
end


--邦定一个已有的句柄
function wygate.bind(os_fd)
	local id = socketdriver.bind(os_fd)
	return connect(id)
end

--获取标准输入句柄
function wygate.stdin()
	return wygate.bind(0)
end

--获取该句柄的事件
function wygate.openclient(id, func)
	socketdriver.start(id)
	return connect(id, func)
end

local function close_fd(id, func)
	local s = socket_pool[id]
	if s then
		if s.connected then
			func(id)
		end
	end
end

function wygate.shutdown(id)
	close_fd(id, socketdriver.shutdown)
end

function wygate.close_fd(id)
	assert(socket_pool[id] == nil,"Use socket.close instead")
	socketdriver.close(id)
end

function wygate.close(id)
	local s = socket_pool[id]
	if s == nil then
		return
	end
	if s.connected then
		socketdriver.close(id)
		-- notice: call socket.close in __gc should be carefully,
		-- because skynet.wait never return in __gc, so driver.clear may not be called
		if s.co then
			-- reading this socket on another coroutine, so don't shutdown (clear the buffer) immediately
			-- wait reading coroutine read the buffer.
			assert(not s.closing)
			s.closing = coroutine.running()
			skynet.wait(s.closing)
		else
			suspend(s)
		end
		s.connected = false
	end
	close_fd(id)	-- clear the buffer (already close fd)
	assert(s.lock == nil or next(s.lock) == nil)
	socket_pool[id] = nil
end

wygate.write = assert(socketdriver.send)
wygate.lwrite = assert(socketdriver.lsend)
wygate.header = assert(socketdriver.header)

function wygate.invalid(id)
	return socket_pool[id] == nil
end

function wygate.listen(host, port, backlog)
	if port == nil then
		host, port = string.match(host, "([^:]+):(.+)$")
		port = tonumber(port)
	end
	return socketdriver.listen(host, port, backlog)
end

function wygate.newclient(conf)
	log.n(TAG,string.format("new client ip[%s] port[%d] ",conf.ip,conf.port))
	local id = socketdriver.connect(conf.ip,conf.port)
	id = connect(id)
	if id then
		socketdriver.start(id)
	end
	return id
end

function wygate.start( handler )

	assert(handler.message)
	assert(handler.connect)

	local CMD = {}

	function CMD.open( source, conf )
		assert(not listenfd)
		local address = conf.address or "0.0.0.0"
		local port = assert(conf.port)
		maxclient = conf.maxclient or 1024
		nodelay = conf.nodelay
		skynet.error(string.format("Listen on %s:%d", address, port))
		listenfd = socketdriver.listen(address, port)
		socketdriver.start(listenfd)
		connect(listenfd, handler.connect)
		if handler.open then
			return handler.open(source, conf)
		end
	end

	function CMD.newclient( source, conf )
		log.n(TAG,string.format("new client ip[%s] port[%d] ",conf.ip,conf.port))
		local id = socketdriver.connect(conf.ip,conf.port)
		id = connect(id)
		if id then
			socketdriver.start(id)
		end
		return id
	end

	function CMD.close()
		assert(listenfd)
		socketdriver.close(listenfd)
	end


	local function unpack_package( sockfd, info)
		local s = socket_pool[sockfd]
		if s == nil then
			return
		end
		s.buffer = s.buffer .. info
		while(true) 
		do
			local size = #s.buffer
			if size < 4 then
				log.d(TAG,string.format("sockfd [%d] data size[%d] less than 4",sockfd,size));
				return 
			end
			local pack_len = string.unpack(">I4",s.buffer)
			if size < pack_len then
				log.d(TAG,string.format("sockfd[%d] data size[%d] less than pack_len[%d] ",sockfd,size, pack_len));
				return
			end

			local data = s.buffer:sub(5,pack_len)
			s.buffer = s.buffer:sub(1+pack_len)
			log.d(TAG,string.format("sockfd[%d] paket end data buffer size[%d] ",sockfd,#s.buffer));
			--skynet.fork(handler.message,sockfd,data,pack_len)
			handler.message(sockfd,data,pack_len);
			--s.cs(handler.message,sockfd,data,pack_len)
		end
	end

	local socket_message = {}
	-- read skynet_socket.h for these macro
	-- SKYNET_SOCKET_TYPE_DATA = 1
	socket_message[1] = function(id, size, data)
		log.d(TAG,string.format("fd[%d] recv data size[%d]",id,size));
		local s = socket_pool[id]
		if s == nil then
			skynet.error("socket: drop package from " .. id)
			socketdriver.drop(data, size)
			return
		end

		local info = skynet.tostring(data,size);
		socketdriver.drop(data,size);
		s.cs(unpack_package,id,info)

	end

	-- SKYNET_SOCKET_TYPE_CONNECT = 2
	socket_message[2] = function(id, _ , addr)
		log.d(TAG,string.format("fd[%d]  connected addr[%s]",id,info,addr));
		local s = socket_pool[id]
		if s == nil then
			return
		end
		-- log remote addr
		s.connected = true
		wakeup(s)
	end

	-- SKYNET_SOCKET_TYPE_CLOSE = 3
	socket_message[3] = function(id)
		log.d(TAG,string.format("fd[%d] closed",id));
		local s = socket_pool[id]
		if s == nil then
			return
		end
		s.connected = false
		wakeup(s)
		handler.disconnect(id)

	end

	-- SKYNET_SOCKET_TYPE_ACCEPT = 4
	socket_message[4] = function(id, newid, addr)
		log.d(TAG,string.format("listen fd[%d] accept new fd[%d] addr[%s]",id,newid,addr));
		local s = socket_pool[id]
		if s == nil then
			socketdriver.close(newid)
			return
		end
		wygate.openclient(newid);
		s.callback(newid, addr)
	end

	-- SKYNET_SOCKET_TYPE_ERROR = 5
	socket_message[5] = function(id, _, err)
		log.d(TAG,string.format("fd[%d] error[%s]",id,err));
		local s = socket_pool[id]
		if s == nil then
			skynet.error("socket: error on unknown", id, err)
			return
		end
		if s.connected then
			skynet.error("socket: error on", id, err)
		elseif s.connecting then
			s.connecting = err
		end
		s.connected = false
		socketdriver.shutdown(id)

		wakeup(s)
	end

	-- SKYNET_SOCKET_TYPE_UDP = 6
	socket_message[6] = function(id, size, data, address)
		local s = socket_pool[id]
		if s == nil or s.callback == nil then
			skynet.error("socket: drop udp package from " .. id)
			socketdriver.drop(data, size)
			return
		end
		local str = skynet.tostring(data, size)
		skynet_core.trash(data, size)
		s.callback(str, address)
	end

	local function default_warning(id, size)
		local s = socket_pool[id]
			local last = s.warningsize or 0
			if last + 64 < size then	-- if size increase 64K
				s.warningsize = size
				skynet.error(string.format("WARNING: %d K bytes need to send out (fd = %d)", size, id))
			end
			s.warningsize = size
	end

	-- SKYNET_SOCKET_TYPE_WARNING
	socket_message[7] = function(id, size)
		log.d(TAG,string.format("fd[%d] warning data size[%d]",id,size));
		local s = socket_pool[id]
		if s then
			local warning = s.warning or default_warning
			warning(id, size)
		end
	end

	skynet.register_protocol {
		name = "socket",
		id = skynet.PTYPE_SOCKET,	-- PTYPE_SOCKET = 6
		unpack = socketdriver.unpack,
		dispatch = function (_, _, t, ...)
			log.d(TAG,string.format("socket type[%d] msg[%s]",t,tostring(...)));
			socket_message[t](...)
		end
	}

	skynet.start(function()
		skynet.dispatch("lua", function (_, address, cmd, ...)
			local f = CMD[cmd]
			log.d(TAG,"recv cmd :" .. cmd);
			if f then
				skynet.ret(skynet.pack(f(address, ...)))
			else
				skynet.ret(skynet.pack(handler.command(cmd, address, ...)))
			end
		end)
	end)
end

return wygate



