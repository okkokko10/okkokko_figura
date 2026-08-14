do return end

---@type Entity
player = player


---@generic D: 1|2|3|4
---@class Matrix<D>
---@field [string] any

---@class Vector
-- -@field [string] any




---Vector
---@param ... number
---@return Vector
function vec(...)
    return vec()
end


---@class BlockState
---@field getPos fun(self:self):Vector
---@field id string
---@field getEntityData fun()

---@class ItemStack
---@field tag table
---@field id string
