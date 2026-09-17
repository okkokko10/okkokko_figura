require"invoke.Invoke"

Invoke:registerByValueNoRest("Keys",function (self, input)
    return Utils.table.getKeys(input)
    -- tostring(value)
end)
:addAlternateNames("K")
:addDoc{
    text = "gets the keys of `tbl`",
    value = "<tbl>",
    ret = "any[]"
}


Invoke:registerOld("Literal",function (self, value, rest)
    return value
end)
:addAlternateNames("Lit")
:addDoc{
    text = "returns the literal value without evaluating it beyond substitutions and json parsing",
    value = "<value>"
}


Invoke:registerByValue("get",function (self, rest,input)
    if type(input) == "table" then
        return Utils.table.getNest(input,rest)
    end
end
):addDoc{
    text = "gets table[ key[1] ][ key[2] ][ key[3] ]...,\n"..
    "where if key is a string key[i] is its ith part delimited by `.`\n" .. 
    "advanced: if key[i] is an array or string, it is unfolded similarly:\n"..
    "  table[ key[1] ][ key[2][1] ][ key[2][2] ][ key[3] ]"
}
:addDoc{
    rest = "<key>",
    value = "<table>",
}
Invoke:registerWithArgs("getkv",{"key","from"},function (self, rest,input)
    local b = input.from
    if type(b) == "table" then
        return Utils.table.getNest(b,input.key)
    end
end
):addDoc{
    value = "{from = <table>, key = <key>}"
}

Invoke:registerByValue("count",function (self, rest, input)
    if type(input) ~= "table" then
        error("expected table, got " .. type(input) .. " " .. toJson(input) .. " from " .. toJson(value))
    end
    local out = {}
    for key, value in pairs(input) do
        out[value] = (out[value] or 0) + 1
    end
    if rest ~= "" then
        return out[rest]
    end
    return out
    -- tostring(value)
end)

Invoke:registerByValue("any",function (self, rest, input)
    if type(input) ~= "table" then
        error("expected table, got " .. type(input) .. " " .. toJson(input)) -- todo: error that gives where the input originated from
    end
    for k, v in pairs(input) do
        return v
    end
end)




Invoke:registerByName("map",function (self, value, rest)
    local tbl = self:materializeBranch(value.table)
    local key = rest
    if not tbl then
        return
    end
    local out = {}
    local old = self:getVariable(key)
    for k, v in pairs(tbl) do
        self:setVariable(key,v)
        if (not value.filter) or self:materializeBranch(value.filter) then
            if value.map then
                out[k] = self:materializeBranch(value.map)
            else
                out[k] = v
            end
        end
    end
    self:setVariable(key,old)
    return out
    
end)

--- deprecated
Invoke:registerOld("filter",function (self, value, rest)
    local filters = {}
    local filterInverts = {}
    -- for modifier, st in string.gmatch(rest,"%(%s*(%-?)%s*(.*)%s*%)") do
    for br in string.gmatch(rest,"%b()") do
        local modifier, st = string.match(br,"(%-?)%s*(.*)$")
        filters[#filters+1] = st
        if modifier == "-" then
            filterInverts[#filters] = true
        end
    end

    local tbl = self:materializeBranch(value)
    if not tbl then
        return
    end
    local out = {}
    for k, v in pairs(tbl) do
        for i = 1, #filters do
            local t = self:call(filters[i],v) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this?
            if (not t) == (not filterInverts[i]) then
                goto continue
            end
        end
        ::continue::
        out[k] = v
    end
    return out
    
end)
:addDoc{
    text = "deprecated in favor of mapchain. filter(a.x)(b.y)(-c.z) = <t> results in taking the resulting table of t and filtering it based on whether an element e passes a.x = {Literal = e}, b.y = {Literal = e} and fails c.z = {Literal = e}"
}


Invoke:registerByValue("chain",function (self, rest, input)
    local commands = {}
    local modifiers = {}
    -- for modifier, st in string.gmatch(rest,"%(%s*([%-%?]?)%s*(.*)%s*%)") do
    local brackets = "%b[]"
    local reverse = false
    if string.match(rest,"^%s*%[") then
        brackets = "%b[]"
        reverse = true
    end
    for br in string.gmatch(rest,brackets) do
        local modifier, st = string.match(br,"^.%s*([%-%+%?1%#]*)%s*(.-)%s*.$")
        commands[#commands+1] = st
        modifiers[#commands] = modifier
    end

    local v = input
    local size = #commands
    local i = 0
    while i < size do
        i=i+1
        if string.match( modifiers[i], "%?") and not v then
            return
        end
        
        local x = self:call(commands[i],v) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this? 
        local mod = string.match( modifiers[i], "[%+%-]")
        local skip = string.match(modifiers[i],"1")
        if mod == "+" then
            if not x then
                if skip then
                    i = i + 1
                else
                    return
                end
            end
        elseif mod == "-" then
            if x then
                if skip then
                    i = i + 1
                else
                    return
                end
            end
        elseif not string.match(modifiers[i],"#") then
            v = x
        end
    end
    return v
    
end)
:addDoc{
    text = "chain(a.x)(b.y)(c.z) = t is equivalent to a.x = { b.y = { c.z = t } }.\n"..
        "if a `?` is at the start of a part, then the chain exits if the value that would be passed into it is nil\n"..
        "if a + or - is at the start, passes its input onto the next link in the chain, and instead exits if its own result is falsey or truthy respectively\n" .. 
        "if there is a 1 at the start, + or - instead just skips the next instruction not everything\n" ..
        "if there is a # at the start, returns what it was passed"
}:addAlternateNames("") -- can be just ()()

Invoke:registerByValue("mapchain",function (self, rest, input)
    if not input then
        return
    end
    local out = {}

    for k, v in pairs(input) do
        out[k] = self:call(rest,v)
    end
    return out
    
end):addAlternateNames("M")

:addDoc{
    text = "chain but for each value of a table."
}

Invoke:registerByValue("eq",function (self, rest, input)
    local tbl = input
    -- log(rest)
    return tbl == parseJson(rest)
    
end)

:addDoc{
    text = "is value equal to rest"
}

Invoke:registerByValue("keyvalue",function (self, rest, input)
    local tbl = input
    if not tbl then return end
    local out = {}
    for key, value in pairs(tbl) do
        out[#out+1] = {key,value}
    end
    return out
end)

Invoke:registerByValue("arrayize",function (self, rest, input)
    local tbl = input
    if not tbl then return end
    local out = {}
    for key, value in pairs(tbl) do
        out[#out+1] = value
    end
    return out
end)


Invoke:registerByValue("concat",function (self, rest, input)
    local tbl = input
    if not tbl then return end
    return table.concat(tbl,rest)
end)

Invoke:registerOld("table",function (self, value, rest)
    local out = {}
    for k, v in pairs(value) do
        out[k] = self:materializeBranch(v)
    end
    return out
end)



Invoke:registerByValue("append", function (self, rest, input)
    local tbl = self:getVariable(rest)
    if type(tbl) == "table" then
        tbl[#tbl+1] = input
    end
    return input
end)



Invoke:registerByValue("Array", function (self, rest, input)
    return {}
end)


Invoke:registerByValue("assign", function (self, rest, input)
    local tbl = self:getVariable(rest)
    if type(tbl) == "table" then
        tbl[input] = true
    end
    return input
end)
