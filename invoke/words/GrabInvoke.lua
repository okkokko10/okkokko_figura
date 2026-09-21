

require"invoke.Invoke"


Invoke:registerKeyword("False",function (self)
    return false
end)

Invoke:registerWithArgs("affix",{"part","parent","target"}, function (self, rest, input)
    AnchorAffix.complex.affixInPlace(input.part,input.parent,input.target,true)
end)


--- >>>[set.target:text.S:Umbrella]
--- >>>[+on.sneak-> text.SpareLineStart -> set.part -> var.target -> set.parent -> affix]
--- 
--- >>>[set.target:text.S:Umbrella]
--- >>>[+on.sneak-> set.part:text.SpareLineStart -> set.parent:var.target -> affix]
--- 
--- 