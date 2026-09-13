require"invoke.Invoke"

Invoke:register("rawJson",function  (self, value, rest)
    return toJson(value)
end)

Invoke:register("text",function  (self, value, rest)
    return rest or ""
end)




Invoke:register("J",function (self,tbl, rest)
    return toJson(self:materializeBranch(tbl))
    -- tostring(value)
end)

Invoke:register("sub",function  (self, value, rest)
    local s = value[1] or value.s
    local pattern = value[2] or value.pattern or value.p
    local repl = value[3] or value.repl or value.r
    local rec = value[4] or value.rec
    local w = self:materializeBranch(s)
    if type(w) ~= "string" then return end
    return string.gsub(w,pattern,repl)
    
end)



Invoke:register("logJson",function  (self, value, rest)
    logTable(value,5)
    -- return toJson(value)
end)


Invoke:register("log",function  (self, value, rest)
    local w = self:materializeBranch(value)
    if self.plr == client.getCameraEntity() then
        local a,q = string.match(rest,"^([^%+]*)%+(%d*)")
        if q then
            if a == "" then
                logTable(w,tonumber(q))
            else
                logTable({[a] = w},(tonumber(q) or 1) + 1)
            end
        else
            log(rest,w)
        end
    end
    return w
    -- return toJson(value)
end)
