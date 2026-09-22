require"invoke.Invoke"


local entitycolors = {
    player = "#F700FF",
    item = "#D0FF00",
    living = "#F3BCCA",
    dead = "#ADBB92"
}

Invoke:registerByValue("entitycolor", function (self, rest, input)
    
    if input:isPlayer() then
        return entitycolors.player
    end
    if input:getType() == "minecraft:item" then
        return entitycolors.item
    end

    if input:isLiving() then
        return entitycolors.living
    end
    return entitycolors.dead


end)