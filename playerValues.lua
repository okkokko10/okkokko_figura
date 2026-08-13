

---@class Entity
PlayerValues = {
}

PlayerValuesOverride = {
    ---@type vec3?
    pos = nil,
    rot = nil,
    bodyYaw = nil
}

--- todo: camera following

function PlayerValues:isLoaded()
    return player:isLoaded()
end
function PlayerValues:getPos(delta)
    -- if not player:isLoaded() then return end
    return PlayerValuesOverride.pos or player:isLoaded() and player:getPos(delta)
end
function PlayerValues:getRot(delta)
    -- if not player:isLoaded() then return end
    return PlayerValuesOverride.rot or player:isLoaded() and player:getRot(delta)
end
function PlayerValues:getBodyYaw(delta)
    -- if not player:isLoaded() then return end
    return PlayerValuesOverride.bodyYaw or player:isLoaded() and player:getBodyYaw(delta)
end
function PlayerValues:getUUID()
    -- if not player:isLoaded() then return end
    return player:getUUID()
end
function PlayerValues:getEyeHeight()
    -- if not player:isLoaded() then return end
    return player:getEyeHeight()
end
function PlayerValues:getLookDir()
    return player:getLookDir()
end
function PlayerValues:getHeldItem()
    return player:getHeldItem()
end
function PlayerValues:getVelocity()
    return player:getVelocity()
end

---comment
---@param entity Entity
---@param delta number?
---@return vec3
function Utils.entity.entityEyePos(entity,delta)
    return entity:getPos(delta) + vec(0, entity:getEyeHeight(), 0)
end





return PlayerValues