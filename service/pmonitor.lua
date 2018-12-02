--
-- Author: shineflag
-- Date: 2017-10-10 10:47:25
-- Desc: 进程监控


local skynet = require "skynet"
local log = require "log"
local httpc = require "http.httpc"


local TAG = "PMONITOR"
local CMD = {}
local pinfo = {} --所有监控进程的信息

local pmonitor = {}  --与进程监控相关的逻辑函数
local notify 

--获取某种进程名称的数量 
function pmonitor.pname_num( pname )
	local cmd = string.format("ps -ef | grep %s | grep -v grep | wc -l",pname)
	local f = io.popen(cmd)
	local num = f:read()
	-- log.d(TAG,"pname[%s] num is %s",pname,num)
	f:close()
	return tonumber(num)
end

function pmonitor.process_restart( pc)
	local cmd = string.format("cd %s && sh %s",pc.dir, pc.sh)
	--log.d(TAG,"exec cmd[%s] ",cmd)
	local result = os.execute(cmd)
	log.d(TAG,"exec cmd[%s] result[%s] ",cmd, result)

	if notify then 
		local respheader = {}
		local path = string.format("%s?sername=%s&phone=%s",notify.path, pc.name, notify.phone)
		log.d(TAG,"url:%s path:%s get:%s%s",notify.url, path, notify.url, path)
		local status, body = httpc.get(notify.url, path, respheader)
		log.d(TAG, "url:%s status:%s body:%s ", url, status, body)
		return result
	end 


end

function pmonitor.process_monitor( pc)
	local pnum = pmonitor.pname_num(pc.pname)
	if pnum < pc.pnum then 
		log.e(TAG,"process[%s] pnum[%d] less than[%d] need restart",pc.name, pnum, pc.pnum)
		pmonitor.process_restart(pc)
	else
		--log.d(TAG,"pname[%s] run normal",pc.name)
	end
end

function pmonitor.run_monitor()
	while(true)
	do
		for _, pc in pairs(pinfo) do 
			pmonitor.process_monitor(pc)
		end
		skynet.sleep(500)
	end
end

--缓存麻将日志
function CMD.init( )
	pinfo = require("pmonitor_conf")
	local ok, conf = pcall(require, "notify_conf")
	if ok then 
		notify = conf 
	end 
	pmonitor.run_monitor()
end
--]]


skynet.start(function()
	skynet.dispatch("lua", function (_, address, cmd, ...)
		local f = CMD[cmd]
		log.d(TAG,"recv cmd :" .. cmd);
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			log.d(TAG,"no cmd :" .. cmd);
		end
	end)
end)


