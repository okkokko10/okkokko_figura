require"invoke.Invoke"

Invoke:register("Keys",function (self, value, rest)
    return Utils.table.getKeys(self:materializeBranch(value))
    -- tostring(value)
end)
:addAlternateNames("K")
:addDoc{
    text = "gets the keys of `tbl`",
    value = "<tbl>",
    ret = "any[]"
}


Invoke:register("Literal",function (self, value, rest)
    return value
end)
:addAlternateNames("Lit")
:addDoc{
    text = "returns the literal value without evaluating it beyond substitutions and json parsing",
    value = "<value>"
}


Invoke:register("get",function (self, value, rest)
    if rest == "" then
        rest = self:materializeBranch(value.key)
        value = value.from
    end
    local b = self:materializeBranch(value)
    if type(b) == "table" then
        return Utils.table.getNest(b,rest)
    end
    -- tostring(value)
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
}:addDoc{
    value = "{from = <table>, key = <key>}"
}

Invoke:register("count",function (self, value, rest)
    local tbl = self:materializeBranch(value)
    if type(tbl) ~= "table" then
        error("expected table, got " .. type(tbl) .. " " .. toJson(tbl) .. " from " .. toJson(value))
    end
    local out = {}
    for key, value in pairs(tbl) do
        out[value] = (out[value] or 0) + 1
    end
    if rest ~= "" then
        return out[rest]
    end
    return out
    -- tostring(value)
end)

Invoke:register("any",function (self, value, rest)
    local tbl = self:materializeBranch(value)
    if type(tbl) ~= "table" then
        error("expected table, got " .. type(tbl) .. " " .. toJson(tbl) .. " from " .. toJson(value))
    end
    for k, v in pairs(tbl) do
        return v
    end
end)




Invoke:register("map",function (self, value, rest)
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
Invoke:register("filter",function (self, value, rest)
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
            local t = self:materializeBranch(filters[i],{Literal = v}) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this?
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


Invoke:register("chain",function (self, value, rest)
    local commands = {}
    local modifiers = {}
    -- for modifier, st in string.gmatch(rest,"%(%s*([%-%?]?)%s*(.*)%s*%)") do
    local brackets = "%b()"
    local reverse = false
    if string.match(rest,"^%s*%[") then
        brackets = "%b[]"
        reverse = true
    end
    for br in string.gmatch(rest,brackets) do
        local modifier, st = string.match(br,"^.%s*([%-%+%?]*)%s*(.-)%s*.$")
        commands[#commands+1] = st
        modifiers[#commands] = modifier
    end

    local v = self:materializeBranch(value)
    for i = reverse and 1 or #commands, reverse and #commands or 1, reverse and 1 or -1 do
        if string.match( modifiers[i], "%?") and not v then
            return
        end
        
        local x = self:materializeBranch(commands[i],{Literal = v}) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this? 
        local mod = string.match( modifiers[i], "[%+%-]")
        if mod == "+" then
            if not x then
                return
            end
        elseif mod == "-" then
            if x then
                return
            end
        else
            v = x
        end
    end
    return v
    
end)
:addDoc{
    text = "chain(a.x)(b.y)(c.z) = t is equivalent to a.x = { b.y = { c.z = t } }.\n"..
        "if a `?` is at the start of a part, then the chain exits if the value that would be passed into it is nil\n"..
        "if a + or - is at the start, passes its input onto the next link in the chain, and instead exits if its own result is falsey or truthy respectively"
}:addAlternateNames("") -- can be just ()()

Invoke:register("mapchain",function (self, value, rest)
    

    local tbl = self:materializeBranch(value)
    if not tbl then
        return
    end
    local out = {}

    for k, v in pairs(tbl) do
        out[k] = self:materializeBranch("chain"..rest,{Literal = v})
    end
    return out
    
end):addAlternateNames("M")

:addDoc{
    text = "chain but for each value of a table."
}

Invoke:register("eq",function (self, value, rest)
    local tbl = self:materializeBranch(value)
    -- log(rest)
    return tbl == parseJson(rest)
    
end)

:addDoc{
    text = "is value equal to rest"
}