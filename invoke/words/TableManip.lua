require"invoke.Invoke"

Invoke:register("Keys",function (self, value, rest, plr)
    return Utils.table.getKeys(self:materializeBranch(value))
    -- tostring(value)
end)
:addAlternateNames("K")
:addDoc{
    text = "gets the keys of `tbl`",
    value = "<tbl>",
    ret = "any[]"
}


Invoke:register("Literal",function (self, value, rest, plr)
    return value
end)
:addAlternateNames("Lit")
:addDoc{
    text = "returns the literal value without evaluating it beyond substitutions and json parsing",
    value = "<value>"
}


Invoke:register("get",function (self, value, rest, plr)
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


Invoke:register("map",function (self, value, rest, plr)
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