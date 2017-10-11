--
-- Author: shineflag
-- Date: 2017-07-10 20:12:14
--

local skynet = require "skynet"
require "skynet.manager"

local logpath = "./"  --日志文件路径
local logfname = "skynet"  --日志文件的默认名称
local files =  { --所有的日志文件
	-- poker = {    -- poker file name
	-- 	fname = "poker", --日志文件的基础名字
	-- 	fd = 13,    --文件名柄
	-- 	lineno = 1, --文件行

 --    },
} 

local MAXLINE = 2000000  --200M左右
local MAXFILE = 10000   --同类文件的当天的最大文件数

----[[
	--当前时间 到北京时区  0时的秒数
--]]
local function tomidtime(  )
    local now = os.time() 
    local beiji = now + 8*3600
    local day_sec = beiji % (3600*24)
    local sec2night = 3600*24 - day_sec
    return sec2night
end

--该文件是否存在
local function logexist( filename )
    local f = io.open(filename,"r")
    if f then
        f:close() 
        return true
    else
        return false
    end
end


--获取该类文件当前时期的最大文件号，超过最大则重复写
local function  updatefilenum( file )
	local fname = file.fname
    local time_info = os.date("%Y%m%d",os.time())
    for i = 1, MAXFILE  do
        local filename =  string.format("%s%s_%s_%d.log",logpath,fname,time_info,i)
        if not logexist(filename) then
            return i
        end
    end
    return 1
end

--根据文件名创建一个新的日志文件
local function create_log_file( fname )
	local file = files[fname]
	if not file then 
		file = {fname=fname}
		files[fname] = file
	end

    if file.fd and io.type(file.fd) == "file" then
        file.fd:close()
    end

    local time_info = os.date("%Y%m%d",os.time())
    local filenum = updatefilenum( file )
    local filename =  string.format("%s%s_%s_%d.log",logpath,fname,time_info,filenum)
    file.fd = io.open(filename,"w")
    file.lineno = 0

    return file
end


--将日志信息写入文件
local function write_file(file,msg)
    file.fd:write(msg)
    file.fd:write("\n")
    file.fd:flush()
    file.lineno = file.lineno + 1
    if file.lineno >= MAXLINE then
        create_log_file(file.fname)
    end

end


--所有文件都会按天分割
local function day_splite_file()

	local timeout = tomidtime() + 1
	for fname,_ in pairs(files) do 
		create_log_file(fname)
	end
	skynet.timeout(timeout * 100,day_splite_file)
end


local function log_msg(_, address, msg)
	local file = files[logfname]
	if not file then
		file = create_log_file(logfname)
	end

	write_file(file, string.format("[%08x] %s", address, msg))

end

skynet.register_protocol {
	name = "text",
	id = skynet.PTYPE_TEXT,
	unpack = skynet.tostring,
	dispatch = log_msg
}

skynet.register_protocol {
	name = "SYSTEM",
	id = skynet.PTYPE_SYSTEM,
	unpack = function(...) return ... end,
	dispatch = function()
		-- reopen signal
		print("SIGHUP")
	end
}



skynet.start(function()
	skynet.register ".logger"
	logpath = skynet.getenv "logpath" or "./"
	logfname = skynet.getenv "logfname" or "skynet"
	day_splite_file()
end)