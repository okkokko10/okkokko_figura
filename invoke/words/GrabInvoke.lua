

require"invoke.Invoke"


Invoke:registerKeyword("False",function (self)
    return false
end)

Invoke:registerByValue("Loaded", function (self, rest, input)

    if not input then return end
    if not input.isLoaded then 
        log("erroring:",input)
        error("does not have loaded: "..tostring(input) .. " of type " .. type(input))
    end
    if input:isLoaded() then
        return true
    end
    return false
end):addAlternateNames("Lo")

Invoke:registerWithArgs("affix",{"part","parent","target"}, function (self, rest, input)

    local parent = input.parent
    if input.parent and input.parent.isLoaded then
        if not input.parent:isLoaded() then
            error("entity not loaded")
            return
        end
        parent = "!pl:".. input.parent:getUUID()
    end
    if not input.part then return end
    AnchorAffix.complex.affixInPlace(input.part,parent,input.target,true)
end)


--- >>>[set.target:text.S:Umbrella]
--- >>>[+on.sneak-> text.SpareLineStart -> set.part -> var.target -> set.parent -> affix]
--- 
--- >>>[set.target:text.S:Umbrella]
--- >>>[+on.sneak-> set.part:text.SpareLineStart -> set.parent:var.target -> affix]
--- 
--- 