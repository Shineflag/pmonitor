--
-- Author: shineflag
-- Date: 2016-09-21 12:08:43
--
local skynet = require "skynet"

local log = {}


log.LV_ERROR = 1 
log.LV_NOTICE = 2 
log.LV_WARN = 3 
log.LV_DEBUG = 4 

local lv_msg ={
	[log.LV_ERROR]  = "ERROR",
	[log.LV_NOTICE] = "NOTICE" ,
	[log.LV_WARN]   = "WARN", 
	[log.LV_DEBUG]  = "DEBUG" 
}

local log_level = log.LV_DEBUG


local function print_msg(msg)
    skynet.error(msg)
end



local function format_msg(lv,tag, ... )
    --local time_info = os.date("%Y-%m-%d %X",os.time())
    local time_info = os.date("%X",os.time())
    local debug_info = debug.getinfo(3)

    local msg 
    if select("#", ...) > 1 then
    	msg = string.format(...)
    else
        msg = tostring(...)
    end
	
    return string.format("%s:%s[%d] %s %s [%s] --> %s",string.match(debug_info.source, ".+/([^/]*%.%w+)$"), debug_info.name, debug_info.currentline, lv_msg[lv],tag, time_info, msg)

end

local function log_error(tag, ... )
    if log_level >= log.LV_ERROR then
        local info = format_msg(log.LV_ERROR,tag,...)
        print_msg(info)
    end
end

local function log_notice(tag, ... )
    if log_level >= log.LV_NOTICE then
        local info = format_msg(log.LV_NOTICE,tag,...)
        print_msg(info)
    end
end

local function log_warn(tag,...)
    if log_level >= log.LV_WARN then
        local info = format_msg(log.LV_WARN,tag,...)
        print_msg(info)
    end
end

function log_debug(tag,...)
    if log_level >= log.LV_DEBUG then
        local info = format_msg(log.LV_DEBUG,tag,...)
        print_msg(info)
    end
end



log.e = log_error
log.n = log_notice
log.w = log_warn
log.d = log_debug

return log
