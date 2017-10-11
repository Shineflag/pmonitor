root = "$ROOT/"
skynet="$SKYNET/"
thread = 8
logpath = root .. "run/"
harbor = 0
start = "main"	-- main script
luaservice = root .. "service/?.lua;" .. skynet .."service/?.lua" 
lualoader = skynet .. "lualib/loader.lua"
lua_path = root .. "lualib/?.lua;" .. skynet .. "lualib/?.lua;" .. skynet .. "lualib/?/init.lua;" .. root .. "etc/conf/?.lua"
lua_cpath = skynet .. "luaclib/?.so"
cpath = skynet.."cservice/?.so"

if $DAEMON then
	logservice = "snlua"
	logger = "skynetlog"
	daemon = root .. "run/skynet.pid"
end
