require"invoke.Invoke"

Invoke:register("rawJson",function  (self, value, rest, plr)
    return toJson(value)
end)

Invoke:register("text",function  (self, value, rest, plr)
    return rest or ""
end)




Invoke:register("J",function (self,tbl, rest, plr)
    return toJson(self:materializeBranch(tbl))
    -- tostring(value)
end)

Invoke:register("sub",function  (self, value, rest, plr)
    local s = value[1] or value.s
    local pattern = value[2] or value.pattern or value.p
    local repl = value[3] or value.repl or value.r
    local rec = value[4] or value.rec
    local w = self:materializeBranch(s)
    if type(w) ~= "string" then return end
    return string.gsub(w,pattern,repl)
    
end)



Invoke:register("logJson",function  (self, value, rest, plr)
    logTable(value,5)
    -- return toJson(value)
end)
