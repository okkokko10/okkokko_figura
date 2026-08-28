require"invoke.Invoke"


-- todo: per-person
Invoke.variables = {}

--- returns old value
function Invoke:setVariable(key,value)
    local old = self.variables[key]
    self.variables[key] = value
    return old
end
function Invoke:getVariable(key)
    return self.variables[key]
end




--- perhaps require that any created ModelPart be assigned a variable?
--- that way, you won't lose track of them
--- but what if you want to set a variable to a ModelPart that already exists?
--- a reference?


--- perhaps require that space is allocated beforehand

--- todo: end a word in ? or some other value to make a value literal
--- or assign its value to the variable 
--- this would be possible to implement with just set and Literal, though.
--- 
--- ?!+-.&%|^*~()$@
--- not /,#


--- set.l.$1.x.$2 = {1 = <key1>, 2 = <key2>}

--- "and" and _runTable have a similar structure?
--- 

-- Invoke:register("set", function (self, value, rest, plr)
--     if rest == "" then
--         local out
--         if type(value) ~= "table" then
--             return
--         end
--         for key, value in pairs(value) do
--             out = self:materializeBranch(value)
--             self:setVariable(key,out)
--         end
--         return out
--     else
--         local out = self:materializeBranch(value)
--         self:setVariable(rest,out)
--         return out
--     end
-- end)


Invoke:register("set", function (self, value, rest, plr)
    if rest == "" then
        rest = self:materializeBranch(value.key)
        if value.onReplace then
            local old = self:getVariable(rest)
            if old then
                self:materializeBranch(value.onReplace)
            end
        end
        value = value.value
    end
    local out = self:materializeBranch(value)
    self:setVariable(rest,out)
    return out
end)

--- return the value. 

Invoke:register("var", function (self, value, rest, plr)
    if rest == "" then
        rest = self:materializeBranch(value)
    end
    return self:getVariable(rest)
    -- local out = self:materializeBranch(value)
    -- self:setVariable(rest,out)
    -- return out
end)


Invoke:register("evaluate", function (self, value, rest, plr)
    return self:materializeBranch(self:materializeBranch(value))
    -- local out = self:materializeBranch(value)
    -- self:setVariable(rest,out)
    -- return out
end)

