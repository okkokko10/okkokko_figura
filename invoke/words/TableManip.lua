
Invoke:register("K",function (self, value, rest, plr)
    return Utils.table.getKeys(self:materializeBranch(value))
    -- tostring(value)
end)
