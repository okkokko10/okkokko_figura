

require"invoke.Invoke"

Invoke:registerByValue("Track",function (self, rest, input)
    return Positioning.setEphemeral(Positioning.constructID(input,rest))

    

end)

Invoke:registerByValue("child",function (self, rest, input)
    assert(type(input) == "ModelPart")
    return input[rest] or input:newPart(rest,rest)
end)

-- Invoke:registerWithArgs("infotext",{"target","text"},function (self, rest, input)
    

-- end)


