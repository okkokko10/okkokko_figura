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


Invoke:registerByValue("run", function (self, rest, input)
    return self:call(self:getVariable(rest),input)
end)

-- Invoke:registerOnlyRest("fun",function (self, rest)
--     local name, vars, body = string.match(rest,"^%s*(%w*)%s*(%b())%s*(%b{})%s*")
-- end)


Invoke:registerByValue("area",function (self, rest, input)
    assert(type(input)=="Vector3")
    return Rect.fromPosSize(input,vec(1,1,1)*(tonumber(rest) or 16))
end)

Invoke:registerByValue("nop",function (self, rest, input)
    return input
end)



Invoke:registerByValue("Scan", function (self, rest, input)
    if type(input) ~= "Rect" then
        return
    end

    local a,b = string.match(rest,"(%b{})(%b{})")
    local final
    if a then
        local e = string.match(b,"%{(.*)%}")
        final = function (block,ret)
            if self:is_stopped() then return end
            self:call(e,ret)
        end
        rest = string.match(a,"%{(.*)%}")
    end

    require("scanning.Scan").foreach(input,
    function (block, num, out_of)
        -- if self:is_stopped() then return true end
        if block:isAir() then return end
        local out = self:call(rest,block)
        -- log("out:", out)
        return out
    end, final).onError = log

end)
