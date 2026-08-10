


---@class HasGetScalePos
---@field getScale fun(self:self):Vector
---@field getPos fun(self:self):Vector

---@class HasSetScalePos
---@field setScale fun(self:self,v:Vector):self
---@field setPos fun(self:self,v:Vector):self

---@class HasGetSetScalePos : HasGetScalePos, HasSetScalePos


---@type ModelPart

---@class Rect : HasPosSize,HasGetScalePos
---@field [1] Vector
---@field [2] Vector
---@field name? string


Rect = {__type = "Rect"}

local Rect_index = {
    center = function (self)
        return (self[1]+self[2])/2
    end,
    size = function (self)
        return Utils.math.vectorAbs(self[2]-self[1])
    end,
    signedSize = function (self)
        return self[2]-self[1]
    end,
    pos1 = function (self)
        return self[1]
    end,
    pos2 = function (self)
        return self[2]
    end,
    min = function (self)
        return self.center-self.size/2
    end,
    max = function (self)
        return self.center+self.size/2
    end
}
Rect_index.pos = Rect_index.center
Rect_index.scale = Rect_index.size
Rect.getScale = Rect_index.scale
Rect.getPos = Rect_index.pos

function Rect:__index(ind)
    local f = Rect_index[ind]
    if f then
        return f(self)
    else
        return Rect[ind]
    end
end


---@param pos Vector
---@param size Vector
---@return Rect
function Rect.fromPosSize(pos,size)
    return setmetatable({pos-size/2,pos+size/2},Rect)
end

---@param pos1 Vector
---@param pos2 Vector
---@return Rect
function Rect.fromEndpoints(pos1,pos2)
    return setmetatable({pos1,pos2},Rect)
end

---returns a copy with min and max
---@return Rect
function Rect:positive()
    return Rect.fromPosSize(self.pos,Utils.math.vectorAbs(self.size))
end

---@param from? Rect
---@return Rect
function Rect:set(from)
    if not from then
        self[1] = vec(0,0,0)
        self[2] = vec(0,0,0)
        return self
    end
    self[1] = from[1]
    self[2] = from[2]
    return self
end

--- works for ItemTask
---@generic S : HasSetScalePos
---@param target S
---@param posScaling? number -- 
---@param scaleScaling? number -- 
---@return S
function Rect:setCenteredItemTo(target,posScaling,scaleScaling)
    return target:setPos((posScaling or 1)*self:getPos()):setScale((scaleScaling or (1/PS)) * self:getScale()) -- embrace the fact that 1 metre is 16 units
end
-- function Rect:setCenteredItemTo(target,posScaling,scaleScaling)
--     return target:setPos((posScaling or PS)*self:getPos()):setScale((scaleScaling or 1) * self:getScale())
-- end


--- works for BlockTask
---@generic S : HasSetScalePos
---@param target S
---@param posScaling? number -- 
---@param scaleScaling? number -- 
---@return S
function Rect:setCornerBlockTo(target,posScaling,scaleScaling)
    return target:setPos((posScaling or 1)*self[1]):setScale((scaleScaling or (1/PS)) * self:getScale())
end
-- function Rect:setCornerBlockTo(target,posScaling,scaleScaling)
--     return target:setPos((posScaling or PS)*self[1]):setScale((scaleScaling or 1) * self:getScale())
-- end


---adds additional data to rect
---@param name string
---@return self
function Rect:setName(name)
    self.name = name
    return self
end

---@return string
function Rect:getName()
    return self.name
end


--- does not take into account rotation.
---@param itemTask HasGetScalePos
function Rect.fromItemTask(itemTask)
    return Rect.fromPosSize(itemTask:getPos(),itemTask:getScale()*PS):setName(itemTask:getName())
end


--- todo?: Rect conversion to Matrix




---@param aabb HasPosSize
---@param abs_matrix Matrix
local function transformAABBAbs(aabb,matrix,abs_matrix)
    local newpos = matrix:apply(aabb.pos)
    local newExt = abs_matrix * Utils.math.vectorAbs(aabb.size:copy())
    return {pos = newpos, size = newExt}
end

---comment
---@param aabb HasPosSize
---@param matrix Matrix
local function transformAABB(aabb,matrix)
    return transformAABBAbs(aabb,matrix,Utils.math.matrix3Abs(matrix))
end

---@param matrix Matrix
---@param abs_matrix Matrix
---@return Rect
function Rect:transformed_absMatrix(matrix,abs_matrix)
    return Rect.fromPosSize(matrix:apply(self.pos),abs_matrix * self.size)
end

--- returns the outer bound for the transformed Rect
---@param matrix Matrix
---@return Rect
function Rect:transformed(matrix)
    return self:transformed_absMatrix(matrix,Utils.math.matrix3Abs(matrix))
end

return Rect