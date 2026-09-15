require"invoke.Invoke"

Invoke:registerOld("rawJson",function  (self, value, rest)
    return toJson(value)
end)

Invoke:registerOnlyRest("text",function  (self, rest)
    return rest or ""
end)




Invoke:registerByValueNoRest("J",function (self,input)
    return toJson(input)
end)

Invoke:registerByValueNoRest("S",function (self,input)
    return tostring(input)
end)



Invoke:registerOld("sub",function  (self, value, rest)
    local s = value[1] or value.s
    local pattern = value[2] or value.pattern or value.p
    local repl = value[3] or value.repl or value.r
    local rec = value[4] or value.rec
    local w = self:materializeBranch(s)
    if type(w) ~= "string" then return end
    return string.gsub(w,pattern,repl)
    
end)



Invoke:registerOld("logJson",function  (self, value, rest)
    logTable(value,5)
    -- return toJson(value)
end)

local function recursives() end


Invoke:registerByValue("formats",function  (self, rest,input)
    local out = {}
    return string.gsub(string.match(rest,"^(.-)%'?$"),"$(%b{})",function (q,...)
        
        return self:call(string.sub(q,2,-2),input)
    end)

    -- return string.format(rest,table.unpack(value))
end)

Invoke:registerByValue("format",function  (self, rest, input)

    return string.gsub(rest,"$(%S*)",function (q,...)
        return input[parseJson(q)]
    end)

    -- return string.format(rest,table.unpack(value))
end)

Invoke:registerByValue("color",function (self, rest, input)
    return {text = input, color = rest}
end)



Invoke:registerOld("log",function  (self, value, rest)
    local w = self:materializeBranch(value)
    if true or self.plr == client.getCameraEntity() then
        local a,q = string.match(rest,"^([^%+]*)%+(%d*)")
        if q then
            if a == "" then
                logTable(w,tonumber(q))
            else
                logTable({[a] = w},(tonumber(q) or 1) + 1)
            end
        else
            if (type(value) == "table") and value[1] then
                log(rest,table.unpack(value))
            else
                log(rest,w)
            end
        end
    end
    return w
    -- return toJson(value)
end)
