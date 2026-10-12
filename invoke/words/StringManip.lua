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
        
        local out = self:call(string.sub(q,2,-2),input)
        return ((out ~= nil) or nil) and tostring(out)
    end)
end):addAlternateNames("f")
-- :compilation(function (self, rest)

--     --- formats.a is ${A} b is ${B}
--     --- compiles to:
--     --- plan: create array, assign results of each ${} to indices,
--     --- then use string.gsub
--     --- 

    
--     local fns = {}
--     local i = 0
--     local flat = string.gsub(string.match(rest,"^(.-)%'?$"),"$(%b{})",function (q,...)
--         i = i + 1

--         local p = self:compileCall(string.sub(q,2,-2))
        
--         fns[i] = p

--         return ("$%d%s"):format(i,q)

--     end)
    

--     local str = ""

-- end)

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

---@class Denominations
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

local currency_upper =
    {"SPUR",
    "BEVEL",
    "SPROCKET",
    "COG",
    "CROWN",
    "SUN"
}


 
    
    
Utils.currency = {}

---lists coins with their symbols
---@param denominations Denominations
---@return string
function Utils.currency.pricestring(denominations)
    local out = ""
    for key, value in ipairs(currency) do
        if denominations[value] and denominations[value]~= 0 then
            out = out .. tostring(denominations[value]) .. currencysymbols[value]
        end
    end
    return out
end
--- for denominations where the keys are UPPERCASE
---@param denominations Denominations
---@return string
function Utils.currency.pricestring_upper(denominations)
    local out = ""
    for key, value in ipairs(currency) do
        local v = currency_upper[key]
        local d = denominations[v]
        if d and d ~= 0 then
            out = out .. tostring(d) .. currencysymbols[value]
        end
    end
    return out
end


---sum a with weights in b
---@generic K,V
---@param a {[K]:V}
---@param b {[K]:V}
---@return V
function Utils.table.dotProduct(a,b)
    local out = 0
    for key, value in pairs(a) do
        if b[key] then
            out = out + value * b[key]
        end
    end
    return out
end

---comment
---@param denominations Denominations
function Utils.currency.price(denominations)
    return Utils.table.dotProduct(denominations,prices)
end

---reads
---@param t {id:string,count:number}?
---@return number
---@return string?
function Utils.currency.fromItemJson(t)
    error("unimplemented")

end

---reads
---@return number
---@return string?
function Utils.currency.fromItemCount(item_id,count)
    local c = string.match(item_id,"^numismatics%:(.*)$")
    if c and prices[c] then
        return count * prices[c]
    else
        return count,item_id
    end
end

Invoke:registerByValue("pricestring",function  (self, rest, input)
    return Utils.currency.pricestring(input)
end)
Invoke:registerByValue("price",function  (self, rest, input)
    return Utils.currency.price(input)
end)

---formats an amount of things in mixed base 64.
---@param amount number
---@param formater string?
---@return string
function Utils.string.stacks(amount,formater)
    if not formater then
        formater = "%s:%s"
    end
    local d = math.floor(amount/64)
    local r = math.fmod(amount,64)
    if d == 0 then
        return tostring(r)
    end

    return string.format(formater,d,r)
end

Invoke:registerByValue("stacks",function  (self, rest, input)
    return Utils.string.stacks(input,(rest~="") and rest or nil)
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


function Utils.string.indentBrackets(str,min_width)
    
end