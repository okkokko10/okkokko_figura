require"invoke.Invoke"



Invoke:register("and",function  (self, value, rest, plr)
    local out
    logTable(value,3)
    if type(value) == "table" then
        for index, value in ipairs(value) do
            out = self:materializeBranch(value,plr)
            self:log(index,out)
            if not out then
                break
            end
        end
    else
        self:log(type(value))
    end
    return out
end)