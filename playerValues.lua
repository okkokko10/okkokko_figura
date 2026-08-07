

---@class Entity
PlayerValues = {
    ---@type vec3?
    pos = nil,
    rot = nil,
}

if false then
    ---@type Entity
    player = player
end

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
function PlayerValues:getEyeHeight()
    -- if not player:isLoaded() then return end
    return player:getEyeHeight()
end


---comment
---@param entity Entity
---@param delta number?
---@return vec3
function entityEyePos(entity,delta)
    return entity:getPos(delta) + vec(0, entity:getEyeHeight(), 0)
end





return PlayerValues