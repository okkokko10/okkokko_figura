
--- plan: create a coroutine object with .new, compose sections
--- calls are wrapped to keep track of stack, Utils.coroutine.vars is a table that changes to the current executing one's
--- how to add control flow? 
---     flag that the current function will lead to itself or the next
---     flag for whether it yields or not. 
--- a coroutine constructor vs instance. 

Utils.coroutine = {}


---@class CoroutineConstructor
---@field funcs (fun(...):...)[]
Utils.coroutine.con = {}
Utils.coroutine.con.__index = Utils.coroutine.con

function Utils.coroutine.constructor()
    local out = setmetatable({funcs={}},Utils.coroutine.con)
    return out
end

---@class Coroutine
---@field con CoroutineConstructor
---@field vars table
---@field pointer integer?
---@field pointer_next integer?
---@field active boolean?
Utils.coroutine.ins = {}
Utils.coroutine.ins.__index = Utils.coroutine.ins


function Utils.coroutine.con:instance(vars)
    local out = setmetatable({con=self,pointer=false,pointer_next = 1,vars= vars or {}},Utils.coroutine.ins)
    return out
end

---@param func fun(...?):...?
function Utils.coroutine.con:add(func)
    table.insert(self.funcs,func)
end



---@type Coroutine?
Utils.coroutine.current = nil
---@type table?
Utils.coroutine.vars = nil

--- pointer is set to current function
function Utils.coroutine.ins:loop(...)
    self.pointer_next = self.pointer
    return ...
end

function Utils.coroutine.ins:no_yield(...)
    self._no_yield = true
    return ...
end


function Utils.coroutine.ins:go(pos,...)
    self.pointer_next = pos
    return ...
end

function Utils.coroutine.ins:halt(...)
    self.pointer_next = nil
    return ...
end


-- if flagged, the next resume continues from the current section, not the next.
function Utils.coroutine.loop(...)
    return assert(Utils.coroutine.current):loop(...)
end
--- if flagged, the return is instead passed onto the next section, which executes immediately
---@param ... unknown
---@return ...
function Utils.coroutine.no_yield(...)
    return assert(Utils.coroutine.current):no_yield(...)
end


--- goto
---@param pos integer
---@param ... unknown
---@return ...
function Utils.coroutine.go(pos,...)
    return assert(Utils.coroutine.current):go(pos,...)
end


--- ends the coroutine
---@param ... unknown
---@return ...
function Utils.coroutine.halt(...)
    return assert(Utils.coroutine.current):halt(...)
end



function Utils.coroutine.ins:isResumable()
    return not not self.pointer_next
end


---@package
function Utils.coroutine._switch(new)
    local old = Utils.coroutine.current
    
    Utils.coroutine.current = new
    Utils.coroutine.vars = new and new.vars

    return old
end



---@param ... unknown
---@return any? continues
---@return ...
function Utils.coroutine.ins:resume(...)

    --- save outer state
    local parent_current = Utils.coroutine._switch(self)

    local t = table.pack(...)
    repeat
        self._no_yield = false


        if self.pointer_next then
            local f = self.con.funcs[self.pointer_next]
            if f then
                self.pointer = self.pointer_next
                self.pointer_next = self.pointer_next + 1 -- this way it increments by default but can change with f
                t = table.pack(f(table.unpack(t)))
            end
            if not self.con.funcs[self.pointer_next] then
                self.pointer_next = nil
            end
        end

    until not self._no_yield


    --- reestablish outer state
    Utils.coroutine._switch(parent_current)
    return self.pointer_next, table.unpack(t)

end


--- todo: for loop
function Utils.coroutine.iter(...)
    error("unimplemented")
end
--- todo: sends the input in iter
function Utils.coroutine.resume(...)
    error("unimplemented")
end

return Utils.coroutine