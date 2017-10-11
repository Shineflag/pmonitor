--
-- Author: shineflag
-- Date: 2017-09-26 14:56:51
--

local skynet = require "skynet"
local log = require "log"

skynet.start(function()

	log.d(TAG,"pmonitor Server start")
	local pm = skynet.uniqueservice "pmonitor"
	skynet.call( pm, "lua", "init")
	
	skynet.exit()
end)
