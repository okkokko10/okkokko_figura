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
    return string.gsub(string.match(rest,"^(.-)%'?$"),"$(%b{})",function (q,...)
        
        return self:call(string.sub(q,2,-2),input)
    end)
end)

Invoke:registerByValue("format",function  (self, rest, input)

    return string.gsub(rest,"$(%S*)",function (q,...)
        return input[parseJson(q)]
    end)
end)


Invoke:registerByValue("formate",function  (self, rest,input)

    return string.gsub(string.match(rest,"^(.-)%'?$"),"$(%b[])",function (q,...)
        return self:call(q,input)
    end)
end)


Invoke:registerByValue("formatq",function  (self, rest,input)
    local out = {}
    string.gsub(rest,"$(%w*)=(%b[])",function (key,q,...)
        out[key] = self:call(q,input)
    end)
    return out
end)



Invoke:registerByValue("color",function (self, rest, input)
    return {text = input, color = rest}
end)


Invoke:registerByValue("Nl",function (self, rest, input)
    return "\n"
end)


Invoke:registerByValue("match",function  (self, rest, input)
    if type(input) ~= "string" then
        error("wrong type:"..type(input))
    end
    return string.match(input,rest)
end)

local prices = {
    spur = 1,
    bevel = 8,
    sprocket = 16,
    cog = 64,
    crown = 512,
    sun = 4096
}
local currency =
    {"spur",
    "bevel",
    "sprocket",
    "cog",
    "crown",
    "sun"}
local currencysymbols = {
    spur = "",
    bevel = "",
    sprocket = "",
    cog = "",
    crown = "",
    sun = ""
}


 
    
    

Invoke:registerByValue("pricestring",function  (self, rest, input)
    local out = ""
    for key, value in ipairs(currency) do
        if input[value] and input[value]~= 0 then
            out = out .. tostring(input[value]) .. currencysymbols[value]
        end
    end
    return out
end)
Invoke:registerByValue("price",function  (self, rest, input)
    local out = 0
    for key, value in pairs(input) do
        if prices[key] then
            out = out + value * prices[key]
        end
    end
    return out
end)

Invoke:registerByValue("stacks",function  (self, rest, input)
    if rest == "" then
        rest = "%s:%s"
    end
    local d = math.floor(input/64)
    local r = math.fmod(input,64)
    if d == 0 then
        return tostring(r)
    end

    return string.format(rest,d,r)
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


Invoke:registerByValue("clipboard",function  (self, rest, input)
    if self.plr == player then
        host:setClipboard(tostring(input))
    end
end)

