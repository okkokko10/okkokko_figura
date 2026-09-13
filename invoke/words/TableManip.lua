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
    local key = rest
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
    text = "filter(a.x)(b.y)(-c.z) = <t> results in taking the resulting table of t and filtering it based on whether an element e passes a.x = {Literal = e}, b.y = {Literal = e} and fails c.z = {Literal = e}"
}


Invoke:register("chain",function (self, value, rest)
    local commands = {}
    local modifiers = {}
    -- for modifier, st in string.gmatch(rest,"%(%s*([%-%?]?)%s*(.*)%s*%)") do
    for br in string.gmatch(rest,"%b()") do
        local modifier, st = string.match(br,"([%-%?]?)%s*(.*)$")
        commands[#commands+1] = st
        modifiers[#commands] = modifier
    end

    local v = self:materializeBranch(value)
    for i = #commands, 1, -1 do
        if modifiers[i] == "?" and v == nil then
            return
        end
        v = self:materializeBranch(commands[i],{Literal = v}) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this? 
    end
    return v
    
end)
:addDoc{
    text = "chain(a.x)(b.y)(c.z) = t is equivalent to a.x = { b.y = { c.z = t } }. if a `?` is at the start of a part, then the chain exits if the value that would be passed into it is nil"
}