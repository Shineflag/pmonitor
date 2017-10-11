--
-- Author: shineflag
-- Date: 2017-07-14 14:31:16
--
local skynet = require "skynet"

local M = {}

M.__index = M

function M.new(...)
    local o = {}
    setmetatable(o, M)
    M.init(o, ...)
    return o
end

function M:init()
    self.tbl = {}    --所有事件的集合
    self.ideid = {}  --所有空闲的id
    self.maxid = 10  --最大的id
    for id = 1, self.maxid do 
		table.insert(self.ideid,id)
	end
end

function M:getid()
	if #self.ideid > 0 then
		return table.remove(self.ideid,1)
	else
		self.maxid = self.maxid + 1
		return self.maxid 
	end
end

-- 启动一个定时器 时间间隔以1/100秒为单位,count=-1表示无限次
function M:start(interval,  func, count)
    local id = self:getid()

    local evt = {interval = interval, count = count or 1, func = func}
    self.tbl[id] = evt

    skynet.timeout(evt.interval, function () self:on_timer(id) end)
    return id
end

function M:on_timer(id)
    local evt = self.tbl[id]
    if not evt then
        return
    end

    if evt.count > 0 then
        evt.count = evt.count - 1
    end

    evt.func()
    if evt.count ~= 0 then
        skynet.timeout(evt.interval, function() self:on_timer(id) end)
    else
    	self.tbl[id] = nil 
    	table.insert(self.ideid, id)
    end
end

--取消一个定时器
function M:cancel(id)
	if  self.tbl[id] then
	    self.tbl[id] = nil
	    table.insert(self.ideid, id)
	end
end

return M
