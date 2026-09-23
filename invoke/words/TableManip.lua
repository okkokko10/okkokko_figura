require"invoke.Invoke"

--- tracks arrays and other tables that are created as outputs in Invoke.
--- plan to use this knowledge to let invoke code only edit these arrays.
Invoke._mutables = setmetatable({},{__mode="k"}) -- __mode="k" makes it so the array will not stop the key from being garbage collected.

--- despite the name, does not need to have contiguous positive integers as inputs.
---@alias Array table


---@return Array
function Invoke:newmutable(out)
    out = out or {}
    self._mutables[out] = true
    return out
end

--- only call to tables you know the origin of
---@param arr table
function Invoke:addToMutables(arr)
    self._mutables[arr] = true
end


---@param arr table|Array|unknown?
---@return boolean
function Invoke:isMutable(arr)
    return not not self._mutables[arr]
end

---@param arr table|Array|unknown?
---@return boolean
function Invoke:isMutableAssertion(arr)
    return assert(self:isMutable(arr),"a variable needs to be a mutable created by an invoke script to be modified")
end

Invoke:registerByValueNoRest("isMutable",function (self, input)
    return self:isMutable(input)
end)


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
Invoke:registerWithArgs("getkv",{"from","key"},function (self, rest,input)
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
    local out = self:newmutable()
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
    local out = self:newmutable()
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
    local out = self:newmutable()
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
    local reverse = true
    -- if string.match(rest,"^%s*%(") then
    --     brackets = "%b()"
    --     reverse = false
    -- end
    for br in string.gmatch(rest,brackets) do
        local modifier, st = string.match(br,"^.%s*([%-%+%?1%#]*)%s*(.-)%s*.$")
        if modifier then
            modifiers[#commands+1] = modifier
            commands[#commands+1] = st
            
        end
    end

    local v = input
    local size = #commands
    local j = 0
    while j < size do
        j=j+1
        local i = j -- reverse and j or (size - j + 1)
        if string.match( modifiers[i], "%?") and not v then
            return
        end
        
        
        local x = self:call(commands[i],v) -- todo: remove the plr argument from materializeBranch. also, is {Literal = x} really the way to do this? 
        
        
        
        local mod = string.match( modifiers[i], "[%+%-]")
        
        
        local skip = string.match(modifiers[i],"1")
        if mod == "+" then
            if not x then
                if skip then
                    j = j + 1
                else
                    if string.match(modifiers[i],"%#") then 
                        return v
                    else
                        return x
                    end
                end
            end
        elseif mod == "-" then
            if x then
                if skip then
                    j = j + 1
                else
                    if string.match(modifiers[i],"%#") then 
                        return v
                    else
                        return x
                    end
                end
            end
        else
            if not string.match(modifiers[i],"%#") then
                v = x
            end
        end
    end
    return v
    
end)
:addDoc{
    text = "chain(a.x)(b.y)(c.z) = t is equivalent to a.x = { b.y = { c.z = t } }.\n"..
        "chain[c.z][b.y][a.x] will pass the input to c.z, then pass its result to b.y, then to a.x, and return that \n"..
        "if a `?` is at the start of a part, then the chain exits if the value that would be passed into it is nil\n"..
        "if a + or - is at the start, passes its input onto the next link in the chain, and instead exits if its own result is falsey or truthy respectively\n" .. 
        "if there is a 1 at the start, + or - instead just skips the next instruction not everything\n" ..
        "if there is a # at the start, returns what it was passed just like + or - does" -- todo: remove "return input" from normal functions?
}:addAlternateNames("") -- can be just ()()

Invoke:registerByValue("mapchain",function (self, rest, input)
    if not input then
        return
    end
    local out = self:newmutable()

    local oldkey = self:getVariable("!key")
    for k, v in pairs(input) do
        self:setVariable("!key",k)
        out[k] = self:call(rest,v)
    end
    self:setVariable("!key",oldkey)
    return out
    
end):addAlternateNames("M")

:addDoc{
    text = "applies the rest to each element of the table. you can get the key with var!key"
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
    local out = self:newmutable()
    for key, value in pairs(tbl) do
        out[#out+1] = {key,value}
    end
    return out
end)
--- out[x] = {k=x, v=input[x]}
Invoke:registerByValue("kv",function (self, rest, input)
    local tbl = input
    if not tbl then return end
    local out = self:newmutable()
    for key, value in pairs(tbl) do
        out[key] = {k=key,v=value}
    end
    return out
end)

Invoke:registerByValue("arrayize",function (self, rest, input)
    local tbl = input
    if not tbl then return end
    local out = self:newmutable()
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
    local out = self:newmutable()
    for k, v in pairs(value) do
        out[k] = self:materializeBranch(v)
    end
    return out
end)



Invoke:registerByValue("append", function (self, rest, input)
    local tbl = self:getVariable(rest)
    self:isMutableAssertion(tbl)
    tbl[#tbl+1] = input
    return input -- todo: should functions return input by default?
end)



Invoke:registerByValue("Array", function (self, rest, input)
    
    local out =  self:newmutable()
    local rs = rest:match("^%s*{(.*)}%s*$")
    if rs then
        for k,w in rs:gmatch("(%w+)%s*%=%s*(%b[])") do
            out[k] = self:call(w,input)
        end
    else
        local i = 1
        for w in rest:gmatch("(%b[])") do
            out[i] = self:call(w,input)
            i = i + 1
        end

    end


    return out
end)


Invoke:registerByValue("assign", function (self, rest, input)
    local tbl = self:getVariable(rest)
    self:isMutableAssertion(tbl)
    tbl[input] = true
    return input
end)

Invoke:registerByValue("nil", function (self, rest, input)
    return
end)

Invoke:registerByValue("copy", function (self, rest, input)
    local out
    if rest == "" then
        out = self:newmutable()
    else
        out = self:getVariable(rest)
        self:isMutableAssertion(out)
    end
    for key, value in pairs(input) do
        out[key] = value
    end
    return out
end):addDoc{
    text = "copies the contents of the input array into a new array or the array variable <rest>, then returns that array"
}





Invoke.regist = setmetatable({},{
    __newindex =function (t, k, v)
        Invoke:registerByValue(k,v)
    end,
    __index =function (t, k)
        return Invoke.function_docs[k]
    end
})



function Invoke.regist.sort(self, rest, input)
    self:isMutableAssertion(input)
    if rest ~= "" then 
        local cache = {}
        for key, value in pairs(input) do
            cache[value] = self:call(rest,value)
        end
        table.sort(input,function (a, b)
            return cache[a] < cache[b]
        end)
    else
        table.sort(input)
    end
    return input
end


Invoke:registerByValue("min", function (self, rest, input)
    local a
    local out
    for key, value in pairs(input) do
        local b = self:call(rest,value)
        if (not a) or b < a then
            a = b
            out = value
        end
    end
    return out
end)

Invoke:registerByValue("size", function (self, rest, input)
    local out = 0

    if rest ~= "" then
        for key, value in pairs(input) do
            if self:call(rest,value) then
                out = out + 1                
            end
        end
        return out
    end
    for key, value in pairs(input) do
        out = out + 1
    end
    return out
end)


Invoke:registerByValue("partition", function (self, rest, input)
    local out = self:newmutable()

    
    for key, value in pairs(input) do
        local q = self:call(rest,value)
        if q ~= nil then
            if not out[value] then
                out[value] = self:newmutable()
            end
            out[value][key] = q
            
        end
    end
    return out
end)

--- group choose: returns triples of a partition key and the first element from that partition and its original key
Invoke:registerByValue("grch", function (self, rest, input)
    local out = self:newmutable()
    local found = {}
    for key, value in pairs(input) do
        local p = self:call(rest,value)
        if p ~= nil then 
            if found[p] then
                local c = found[p].c + 1
                found[p].c = c
                found[p].l[c] = value
            else
                local i = #out+1
                local r = self:newmutable{p=p,v=value,k=key,i=i,c=1,l={value}}
                out[i] = r
                found[p] = r
            end
        end
    end
    return out
end)