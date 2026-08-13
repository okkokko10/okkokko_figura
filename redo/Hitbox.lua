
require"./Rect"

--- a group of AABBs that transform with a common matrix
---@class Hitbox
---@field matrix ConvertsToMatrix
---@field AABBs {[any] : Rect}
Hitbox = {}
Hitbox.__index = Hitbox
Hitbox.__type = "Hitbox"

function Hitbox:createOne(matrix,pos1,pos2)
    return setmetatable({matrix=matrix,AABBs = {Rect.fromEndpoints(pos1,pos2)}},Hitbox)
end

---@alias Vector3 Vector
---@alias VectorWorld Vector3

---comment
---@param matrix ConvertsToMatrix
---@param box Rect|Rect[]|Vector3
---@param b Rect|Vector3?
---@param ... Rect?
---@return Hitbox
function Hitbox:create(matrix,box,b,...)
    local AABBs
    if type(box) == "table" then
        AABBs = box
    elseif type(box) == "Vector3" then
        if type(b) ~= "Vector3" then error("incorrect arguments") end
        AABBs = {Rect.fromEndpoints(box,b)}
    else
        AABBs = {box,b,...}
    end

    return setmetatable({matrix=matrix,AABBs = AABBs},Hitbox)
end

---returns the index
---@param rect Rect
---@return integer
function Hitbox:addRect(rect)
    self.AABBs[#self.AABBs+1] = rect
    return #self.AABBs
end

---@class HitboxRaycastOutput
---@field hitbox Hitbox
---@field rect Rect
---@field index number
---@field globalPos vec3
---@field localPos vec3
---@field distanceSq number
---@field side string?
---@field objectKey? any -- when raycasting a table of multiple Hitboxes, is the key


---
---@param startPos VectorWorld
---@param endPos VectorWorld
---@return HitboxRaycastOutput?
function Hitbox:raycastOriented(startPos,endPos,scaleScaling)
    local ptwm = Conversion.toMatrix(self.matrix)
    local wtpm = ptwm:inverted()
    local aabbs = self.AABBs
    local tbl,pos,side,ind = raycast:aabb(wtpm:apply(startPos)/(scaleScaling or 1),wtpm:apply(endPos)/(scaleScaling or 1),aabbs)
    if tbl then
        local globalPos = ptwm:apply(pos)
        local distanceSq = (globalPos-startPos):lengthSquared()
        return {hitbox=self,index=ind, rect=tbl, globalPos = globalPos, localPos = pos, distanceSq = distanceSq, side = side}
    end
end


-- raycast:aabb(vec(0,0,0),vec(0,0,1),{{}})

---comment
---@param startPos VectorWorld
---@param endPos VectorWorld
---@param objects (Hitbox|HasHitbox)[]
---@return HitboxRaycastOutput?
function Hitbox.raycastsOriented(startPos,endPos,objects)
    local out
    local distanceSq = (endPos-startPos):lengthSquared()
    for key, value in pairs(objects) do
        local out1 = (value.hitbox or value):raycastOriented(startPos,endPos)
        if out1 and out1.distanceSq < distanceSq then
            distanceSq = out1.distanceSq
            out = out1
            out.objectKey = key
        end
    end
    return out
end





---does not take into account rotated items
---@param part IDS<ModelPart>
---@return Hitbox
---@return table keyToIndex
---@return table indexToKey
function Hitbox.fromModelPartItems(part)
    local aabbs = {}
    local keyToIndex = {}
    local indexToKey = {}
    for key, value in pairs(Utils.ID.materialize(part):getTask()) do
        if type(value) == "ItemTask" then
            aabbs[#aabbs+1] = Rect.fromItemTask(value):setName(value:getName())
            keyToIndex[key] = #aabbs
            indexToKey[#aabbs] = key
        end
    end
    return Hitbox:create(part,aabbs),keyToIndex,indexToKey
end

return Hitbox