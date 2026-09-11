do return end

---@type Entity
player = player


---@generic D: 1|2|3|4
---@class Matrix<D>
---@field [string] any

---@class Vector
-- -@field [string] any

---@class Vector
local Vector = {}

---comment
---@param n number?
---@return Vector
function Vector:augmented(n) error() end



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

---@generic T
---@param a T
---@param b T
---@param t number
---@return T
function math.lerp(a,b,t) error() end
---@generic T
---@param a T
---@param b T
---@param t number
---@return T
function math.lerpAngle(a,b,t) error() end


---@generic T
---@param value T
---@param oldMin T
---@param oldMax T
---@param newMin T
---@param newMax T
---@return T
function math.map(value, oldMin, oldMax, newMin, newMax) error() end