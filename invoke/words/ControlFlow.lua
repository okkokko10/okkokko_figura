require"invoke.Invoke"



Invoke:registerByName("and",function  (self, value, rest)
    local out
    logTable(value,3)
    if type(value) == "table" then
        for index, value in ipairs(value) do
            out = self:materializeBranch(value)
            self:log(index,out)
            if not out then
                break
            end
        end
    else
        self:log(type(value))
    end
    return out
end):addDoc{
    text = "returns <valueN> if all are true. has short-circuiting, so a falsey stops latter arguments from evaluating",
    value = "[<value1>,<value2>,...<valueN>]"
}




--- todo: set.x = <value>,  var.x,   filter.x, map.x, bind the variable x to use with var.x

--- todo: filter = {f = }