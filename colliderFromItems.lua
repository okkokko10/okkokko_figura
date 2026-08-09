

ColliderFromItems = {}

---comment
---@param part ModelPart
---@param out Hitbox[]
function ColliderFromItems.getModelItemCollidersAligned(part,out)
    out =  out or {}
    for key, value in pairs(part:getTask()) do
        if type(value) == "ItemTask" then
            out[#out+1] = {pos = value:getPos(), size = value:getScale()}
        end
    end
    return out
end

return ColliderFromItems