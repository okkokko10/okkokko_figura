require"invoke.Invoke"


Invoke:register("equals",function  (self, value, rest, plr)
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