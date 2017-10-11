--
-- Author: shineflag
-- Date: 2017-10-10 10:50:34
--
local gdir="/data/gameserver/"
return {
	{name="日志进程", pname="LogServer",        pnum=1,   dir=gdir .. "LogServer/bin/",         sh="start.sh"},
	{name="广播进程", pname="BroadcastServer",  pnum=1,   dir=gdir .. "BroadcastServer/bin/",   sh="start.sh"},
	{name="金币落地", pname="GoldUpdateServer", pnum=1,   dir=gdir .. "GoldUpdateServer/bin/",  sh="start.sh"},
	{name="金币进程", pname="MDataServer",      pnum=1,   dir=gdir .. "MDataServer/bin/",       sh="start.sh"},
	{name="统计进程", pname="TJServer",         pnum=1,   dir=gdir .. "TJServer/bin/",          sh="start.sh"},
	{name="用户进程", pname="UserServer",       pnum=10,  dir=gdir .. "UserServer/bin/",        sh="start.sh"},
	{name="配桌进程", pname="AllocServer",      pnum=1,   dir=gdir .. "AllocServer/bin/",       sh="start.sh"},
	{name="麻将进程", pname="MajiangServer",    pnum=3,   dir=gdir .. "MajiangServer/bin/",     sh="start.sh"},
	{name="大厅进程", pname="HallServer",       pnum=1,   dir=gdir .. "HallServer/bin/",        sh="start.sh"},
} 