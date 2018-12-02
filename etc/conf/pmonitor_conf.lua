--
-- Author: shineflag
-- Date: 2017-10-10 10:50:34
--
local gdir="/data/dp/run"
-- local gdir="/deploy/server/PokerGo/run"
return {
	{name="Texas", pname="CZTexasServer",        pnum=1,   dir=gdir,         sh="run_texas.sh"},
	{name="Money", pname="CZMoneyServer",        pnum=1,   dir=gdir ,        sh="run_money.sh"},
	{name="Match", pname="CZMatchListServer",    pnum=1,   dir=gdir,         sh="run_matchList.sh"},
	{name="Access", pname="CZAccessServer",       pnum=1,   dir=gdir,         sh="run_access.sh"},
	{name="Club",   pname="CZClubServer",         pnum=1,   dir=gdir,         sh="run_club.sh"},
	{name="Log", pname="CZGamelogServer",      pnum=1,   dir=gdir,         sh="run_gamelog.sh"},
	{name="Notify",   pname="CZNotifyServer",       pnum=1,   dir=gdir,         sh="run_notify.sh"},
	{name="State",   pname="CZStateServer",        pnum=1,   dir=gdir,         sh="run_state.sh"},
	{name="Statis",   pname="CZStatisticServer",    pnum=1,   dir=gdir,         sh="run_statistic.sh"},
} 
