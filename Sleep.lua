
--- unused
--- note: despite being a linked list, is not immutable.
---@generic T
---@class LinkedListOrder<T>
---@field key number
---@field value T
---@field next LinkedListOrder<T>
local LinkedListOrder = {}
LinkedListOrder.__index = LinkedListOrder


function LinkedListOrder.top()
    return setmetatable({empty=true,key=math.huge},LinkedListOrder)
end

---@generic T
---@param next LinkedListOrder<T>?
---@return LinkedListOrder<T>
function LinkedListOrder.bot(next)
    return setmetatable({empty=true,bot=true,next=next,key=-math.huge},LinkedListOrder)
end


---@return LinkedListOrder
function LinkedListOrder.empty()
    return LinkedListOrder.bot(LinkedListOrder.top())
end

---@generic T
---@param value T
---@param key number
---@return LinkedListOrder<T>
function LinkedListOrder.one(value,key)
    return LinkedListOrder.empty():add(value,key)
end



---@param value T
---@param key number
---@return LinkedListOrder<T>
function LinkedListOrder:add(value, key)
    if self.key < key then
        self.next = self.next:add(value,key)
        return self
    else
        return setmetatable({next=self,value=value,key=key},LinkedListOrder)
    end
end

--- if key is nil, pops regardless, unless it's top
---@param key number?
---@return boolean success
---@return LinkedListOrder<T>
---@return T?
---@return number?
function LinkedListOrder:popLT(key)
    if self.key < key then
        return true, self.next, self.value, self.key
    else
        return false, self
    end
end

--- pops regardless of the key, unless it's top
---@return boolean success
---@return LinkedListOrder<T>
---@return T?
---@return number?
function LinkedListOrder:popLTAny()
    if (self.key < math.huge) then
        return true, self.next, self.value, self.key
    else
        return false, self
    end
end



--- pops the next on top of this one if it's lower than key
---@param key number?
---@return boolean
---@return T?
---@return number?
function LinkedListOrder:popLTNext(key)
    ---why is this needed?
---@diagnostic disable-next-line: param-type-mismatch
    local succ, n, v, k = self.next:popLT(key)
    if succ then
        self.next = n
        return true,v,k
    end
    return false, nil, nil
end
function LinkedListOrder:peekLTNext(key)
    local succ, n, v, k = self.next:popLT(key)
    if succ then
        return true,v,k
    end
    return false, self.next.value, self.next.key
end


---unused
---@generic T
---@class FutureCall<T>
---@field [1] fun(...:unknown):T
---@field [number] unknown
---@field callbacks? FutureCall[]
local FutureCall = {}
FutureCall.__index = FutureCall


---@generic T
---@param func fun(... : unknown):T
---@param ... unknown
---@return FutureCall<T>
function FutureCall.prepare(func,...)
    return setmetatable(table.pack(func,...),FutureCall)
end

function FutureCall:call(...)

    if not self.succ_res then
        if select("#",...) == 0 then
            self.succ_res = table.pack(pcall(table.unpack(self)))
        else
            self.succ_res = table.pack(pcall(self[1], ...))
        end
        if self.succ_res[1] then
            for index, value in ipairs(self.callbacks or {}) do
                value:call(table.unpack(self.succ_res,2))
            end
        end
        self.callbacks = nil
    end
    return table.unpack(self.succ_res,2)

end
---comment
---@param func any
---@param ... unknown only get used if self returns nothing
function FutureCall:map(func,...)
    if not self.callbacks then
        self.callbacks = {}
    end
    --- this is abuse.
    local out = FutureCall.prepare(func,...)
    self.callbacks[#self.callbacks+1] = out
    return out
end




Sleep = {}

-- ---@type LinkedListOrder<fun()>
-- Sleep._queued = LinkedListOrder.empty()
-- Sleep._queued_entity = LinkedListOrder.empty()
---@package
Sleep._queued = {}


function Sleep:queueAt(time,func,...)
    self:_init()
    log("queued:",time,func,...)
    time = math.floor(time or 0)
    if time <= self.last_time then
        time = self.last_time + 1
    end
    local t = self._queued[time]
    if t then
        t[#t+1] = table.pack(func,...)
    else
        self._queued[time] = {table.pack(func,...)}
    end
end

---@package
function Sleep:getTime()
    return world.getTime()
end

function Sleep:queue(ticks,func,...)
    self:queueAt(world.getTime() + (ticks or 0),func,...)
end

---@package
function Sleep:_world_tick()
    self = self or Sleep
    local current_time = world.getTime()
    for time = self.last_time, current_time do
        local t = self._queued[time]
        if t then
            for i = 1, #t do
                local succ, res = pcall(table.unpack(t[i]))
                if not succ then
                    log("error in Sleep: ", res, table.unpack(t[i]))
                end
            end
            self._queued[time] = nil
        end
    end
    self.last_time = current_time
    -- while true do
    --     local succ, v, k = self._queued:popLTNext(self:getTime())
    --     if succ then
    --     else
    --         break
    --     end
    -- end
end

---@package
-- todo: events.TICK, for things that should happen as soon as the player is in render distance. needs consideration for the data structure.
function Sleep:_init()
    Sleep._initialized = true
    Sleep.last_time = world.getTime()
    events.WORLD_TICK:register(Sleep._world_tick)
    self._init = Utils.nop
end

return Sleep