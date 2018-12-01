--
-- Author: shineflag
-- Date: 2017-10-10 10:50:34
--
local gdir="/deploy/server/PokerGo/run"
return {
	{name="德州进程", pname="CZTexasServer",        pnum=1,   dir=gdir,         sh="run_texas.sh"},
	{name="金币进程", pname="CZMoneyServer",        pnum=1,   dir=gdir ,        sh="run_money.sh"},
	{name="比赛列表", pname="CZMatchListServer",    pnum=1,   dir=gdir,         sh="run_matchList.sh"},
	{name="接入进程", pname="CZAccessServer",       pnum=1,   dir=gdir,         sh="run_access.sh"},
	{name="俱乐部",   pname="CZClubServer",         pnum=1,   dir=gdir,         sh="run_club.sh"},
	{name="游戏日志", pname="CZGamelogServer",      pnum=1,   dir=gdir,         sh="run_gamelog.sh"},
	{name="通知服",   pname="CZNotifyServer",       pnum=1,   dir=gdir,         sh="run_notify.sh"},
	{name="状态服",   pname="CZStateServer",        pnum=1,   dir=gdir,         sh="run_state.sh"},
	{name="统计服",   pname="CZStatisticServer",    pnum=1,   dir=gdir,         sh="run_statistic.sh"},
} 