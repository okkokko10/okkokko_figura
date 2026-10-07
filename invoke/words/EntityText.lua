

require"invoke.Invoke"

Invoke:registerByValue("Track",function (self, rest, input)
    return Positioning.constructID(input,rest)
end)

-- Invoke:registerWithArgs("infotext",{"target","text"},function (self, rest, input)
    

-- end)


