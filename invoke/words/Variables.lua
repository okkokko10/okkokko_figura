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

-- Invoke:register("set", function (self, value, rest)
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


Invoke:registerByValue("set", function (self, rest, input)
    self:setVariable(rest,input)
    return input
end)

Invoke:registerWithArgs("setkv",{"key","value"}, function (self, rest, inputs)
    self:setVariable(inputs.key,inputs.value)
    return inputs.value
end)


---deprecated
Invoke:registerOld("init", function (self, value, rest)
    if rest == "" then
        rest = self:materializeBranch(value.key)
        value = value.value
    end
    
    local old = self:getVariable(rest)
    if old then return old end
    local out = self:materializeBranch(value)
    self:setVariable(rest,out)
    return out
end)
:addDoc{
    text = "like `set`, but only runs if the variable didn't exist beforehand."
}


--- return the value. 

Invoke:registerOnlyRest("var", function (self, rest)
    return self:getVariable(rest)
end)

Invoke:registerByValueNoRest("varkv", function (self, input)
    return self:getVariable(input)
    -- local out = self:materializeBranch(value)
    -- self:setVariable(rest,out)
    -- return out
end)


Invoke:registerByValueNoRest("evaluate", function (self, input)
    return self:materializeBranch(input)
end)


Invoke:registerByValueNoRest("UtilsID", function (self, input)
    return Utils.ID.from(input)
end)

Invoke:registerByValue("fun", function (self, rest, input)
    local name, func = string.match(rest,"^(%w*):(.*)$")
    
    self:setVariable(name,func)
end)