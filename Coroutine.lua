
--- plan: create a coroutine object with .new, compose sections
--- calls are wrapped to keep track of stack, Utils.coroutine.vars is a table that changes to the current executing one's
--- how to add control flow? 
---     flag that the current function will lead to itself or the next
---     flag for whether it yields or not. 
--- a coroutine constructor vs instance. 

Utils.coroutine = {}


---@class CoroutineConstructor<F>
---@field funcs (F|(fun(...):...))[]
---@field labels { [any] : integer }
---@field direct_onto {[integer] : boolean} -- sections that when advanced to by another section, there is no yield,
Utils.coroutine.con = {}
Utils.coroutine.con.__index = Utils.coroutine.con
Utils.coroutine.con.__type = "CoroutineConstructor"


---@class Coroutine
---@field con CoroutineConstructor
---@field vars table
---@field pointer integer?
---@field pointer_next integer|boolean? -- the value true means advance to the next
---@field active boolean? -- todo: whether this is executing, including if a child is
---@field parent? Coroutine
---@field child? Coroutine -- currently active recursion child
---@field latest_child_vars? table
Utils.coroutine.ins = {}
Utils.coroutine.ins.__index = Utils.coroutine.ins
Utils.coroutine.ins.__type = "Coroutine"



function Utils.coroutine.constructor()
    local out = setmetatable({funcs={}, labels={}, direct_onto = {}},Utils.coroutine.con)
    return out
end

--#region builder




---adds a label that can be used in :go to goto the section added after this
---@param l any
---@return CoroutineConstructor
function Utils.coroutine.con:label(l)
    self.labels[l] = #self.funcs+1
    return self
end

---@alias CoroutineAddable (fun(...?):...?)|CoroutineConstructor

---@param section CoroutineAddable?
function Utils.coroutine.con:add(section)
    if not section then
        return self
    end
    return ({
        ["function"] = Utils.coroutine.con.addFunc,
        ["CoroutineConstructor"] = Utils.coroutine.con.addCoroutine
    })[type(section)](self,section)
end

---@param func fun(...?):...?
function Utils.coroutine.con:addFunc(func)
    table.insert(self.funcs,func)
    return self
end

function Utils.coroutine.ins:exitChild()
    self.child = nil
end

local function nesting_loopIf(cond, ...)
    if cond then
        return assert(Utils.coroutine.current):loop(...)
    else
        Utils.coroutine.current:exitChild()
        return ...
    end
end


---@param constr CoroutineConstructor
---@return function
local function nesting(constr)
    return function (...)
        if not Utils.coroutine.current.child then
            local vars = {}
            Utils.coroutine.current.latest_child_vars = vars
            local child = constr:instance(vars)
            Utils.coroutine.current.child = child -- maybe use some other way to store this
            child.parent = Utils.coroutine.current
        end
        return nesting_loopIf(Utils.coroutine.current.child:resume(...))
    end

end


---@param constr CoroutineConstructor
function Utils.coroutine.con:addCoroutine(constr)
    return self:addFunc(nesting(constr))
end

-- todo: "glue" which modifies the previous such that if it would advance to the next, it does so with no yield

--- a section leading to the next section will have no_yield
---@param section? CoroutineAddable
---@return CoroutineConstructor
function Utils.coroutine.con:glue(section)
    self.direct_onto[#self.funcs+1] = true
    if section then
        self:add(section)
    end
    return self
end

---modifies the previous such that if it would advance to the next, it does so with no yield
---@return CoroutineConstructor
function Utils.coroutine.con:pipe()
    local f = self.funcs[#self.funcs]
    self.funcs[#self.funcs] = function (...)
        local t = table.pack(f(...))
        if Utils.coroutine.current:successing() then
            Utils.coroutine.no_yield()
        end
        return table.unpack(t)
    end
    return self
end


--- takes the first value of the input, then repeats section that many times 
--- (repeat n times: the first n times this advances to the next, it instead loops)
--- hm, what happens if this is gotod out of and then reentered?
---@param section CoroutineAddable? -- modifies previous otherwise
---@return CoroutineConstructor
function Utils.coroutine.con:rep(section)
    local sentinel = Utils.table.kmode()

    self:add(section)
    local f = self.funcs[#self.funcs]
    self.funcs[#self.funcs] = function (...)
        if not sentinel[Utils.coroutine.current] then
            sentinel[Utils.coroutine.current] = (...)
            if ... and ... > 0 then
                Utils.coroutine.loop()
            end
            return "loop start", ..., nil
        end
        if sentinel[Utils.coroutine.current] <= 0 then
            error("is this possible?")
        else
            local t = table.pack(f(...))
            if Utils.coroutine.current:successing() then
                    sentinel[Utils.coroutine.current] = sentinel[Utils.coroutine.current] - 1
                    if sentinel[Utils.coroutine.current] > 0 then 
                        Utils.coroutine.loop()
                    else
                        sentinel[Utils.coroutine.current] = nil
                    end
            end
            return table.unpack(t)
        end
    end


    return self
end




--#endregion builder



--#region instance



---@param vars table?
---@return Coroutine
function Utils.coroutine.con:instance(vars)
    local out = setmetatable({con=self,pointer=nil,pointer_next = 1,vars= vars or {}},Utils.coroutine.ins)
    return out
end


function Utils.coroutine.ins:isResumable()
    return not not self.pointer_next
end


function Utils.coroutine.ins:getLatestChildVars()
    return self.latest_child_vars
end


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
    self.pointer_next = self.con.labels[pos] or pos
    return ...
end

function Utils.coroutine.ins:halt(...)
    self.pointer_next = nil
    return ...
end

--#endregion instance


--#region current

---@type Coroutine?
Utils.coroutine.current = nil
--- equal to Utils.coroutine.current.vars
---@type table?
Utils.coroutine.vars = nil

-- if flagged, the next resume continues from the current section, not the next.
function Utils.coroutine.loop(...)
    return assert(Utils.coroutine.current):loop(...)
end
function Utils.coroutine.loopIf(cond, ...)
    if cond then
        return assert(Utils.coroutine.current):loop(...)
    else
        return ...
    end
end


--- if flagged, the return is instead passed onto the next section, which executes immediately
---@param ... unknown
---@return ...
function Utils.coroutine.no_yield(...)
    return assert(Utils.coroutine.current):no_yield(...)
end


--- goto
---@param pos any
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

--#endregion current




---@package
function Utils.coroutine._switch(new)
    local old = Utils.coroutine.current
    
    Utils.coroutine.current = new
    Utils.coroutine.vars = new and new.vars

    return old
end


local pointer_next_succ_sentinel = {"succ_sentinel"}
local function is_pointer_next_succ_sentinel(s)
    return s == pointer_next_succ_sentinel
end

function Utils.coroutine.ins:successing()
    return is_pointer_next_succ_sentinel(self.pointer_next)
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
            assert(type(self.pointer_next) == "number")
            local f = self.con.funcs[self.pointer_next]
            if f then
                self.pointer = self.pointer_next
                self.pointer_next = pointer_next_succ_sentinel -- this way it increments by default but can change with f
                t = table.pack(f(table.unpack(t)))
                if is_pointer_next_succ_sentinel(self.pointer_next) then
                    self.pointer_next = self.pointer + 1
                end
                if self.con.direct_onto[self.pointer_next] then
                    self:no_yield()
                end
            end
            -- if not self.con.funcs[self.pointer_next] then
            --     self.pointer_next = nil
            

        end

    until not self._no_yield


    --- reestablish outer state
    Utils.coroutine._switch(parent_current)
    return self.con.funcs[self.pointer_next] and self.pointer_next, table.unpack(t)

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