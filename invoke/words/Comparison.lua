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