require"invoke.Invoke"


Invoke:registerByName("lazyequals",function  (self, value, rest)
    local out
    if type(value) == "table" then
        for index, v in ipairs(value) do
            local o = self:materializeBranch(v)
            if out == nil then
                out = o
            else
                if out ~= o then
                    return false
                end
            end
        end
        return true
    end
end):addDoc{
    text = "returns true if all values are equal. has short-circuiting.",
    value = "[<value1>,<value2>,...<valueN>]"
}

Invoke:registerWithArgs("equal",{"left","right"},function  (self, rest,input)
    return input.left == input.right
end)


Invoke:registerOnlyRest("const",function  (self, rest)
    return parseJson(rest)
end)


Invoke:registerWithArgs("minus",{"left","right"},function  (self, rest,input)
    return input.left - input.right
end)
Invoke:registerWithArgs("plus",{"left","right"},function  (self, rest,input)
    return input.left + input.right
end)
Invoke:registerWithArgs("div",{"left","right"},function  (self, rest,input)
    return input.left / input.right
end)
Invoke:registerWithArgs("fdiv",{"left","right"},function  (self, rest,input)
    return math.floor(input.left / input.right)
end)
Invoke:registerWithArgs("mul",{"left","right"},function  (self, rest,input)
    return input.left * input.right
end)

Invoke:registerByValueNoRest("complement",function (self, input)
    return 1-input
end)

Invoke:registerWithArgs("lerp",{"zero","one","t"},function  (self, rest,input)
    return math.lerp(input.zero,input.one,input.t)
end)


Invoke:registerOnlyRest("fromHex",function (self, rest)
    return vectors.hexToRGB(rest)
end)

Invoke:registerByValue("vec",function (self, rest,input)
    return vec(tonumber(input[1]),tonumber(input[2]),tonumber(input[3]),tonumber(input[4]))
end)
Invoke:registerByValueNoRest("rgb",function (self, input)
    return "#"..vectors.rgbToHex(input)
end)