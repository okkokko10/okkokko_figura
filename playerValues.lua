
PlayerValues = {
    ---@type vec3?
    pos = nil,
    rot = nil,
}

function PlayerValues:isLoaded()
    return player:isLoaded()
end
function PlayerValues:getPos(delta)
    -- if not player:isLoaded() then return end
    return PlayerValues.pos or player:isLoaded() and player:getPos(delta)
end
function PlayerValues:getRot(delta)
    -- if not player:isLoaded() then return end
    return PlayerValues.rot or player:isLoaded() and player:getRot(delta)
end
function PlayerValues:getUUID()
    -- if not player:isLoaded() then return end
    return player:getUUID()
end