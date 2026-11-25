
require"./Rect"

--- a group of AABBs that transform with a common matrix
---@class Hitbox
---@field matrix ConvertsToMatrix
---@field AABBs {[any] : Rect}
---@field disabled boolean?
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

---@class HitboxRaycastOutput<Owner>
---@field hitbox Hitbox
---@field rect Rect
---@field index number
---@field globalPos vec3
---@field localPos vec3
---@field distanceSq number
---@field side string?
---@field objectKey? any -- when raycasting a table of multiple Hitboxes, is the key
---@field owner Owner -- 
---@
---@field relative_startPos Vector3 -- in local coordinates, the position of the startPos relative to the hit
local HitboxRaycastOutput = {}
HitboxRaycastOutput.__index = HitboxRaycastOutput
HitboxRaycastOutput.__type = "HitboxRaycastOutput"

local function HitboxRaycastOutput_new(tbl)
    return setmetatable(tbl,HitboxRaycastOutput)
    
end



---
---@param startPos VectorWorld
---@param endPos VectorWorld
---@return HitboxRaycastOutput<nil>?
function Hitbox:raycastOriented(startPos,endPos,scaleScaling)
    if self.disabled then return end
    local ptwm = Conversion.toMatrix(self.matrix)
    local wtpm = ptwm:inverted()
    local aabbs = self.AABBs
    local local_startPos = wtpm:apply(startPos)/(scaleScaling or 1)
    local local_endPos = wtpm:apply(endPos)/(scaleScaling or 1)
    local tbl,pos,side,ind = raycast:aabb(local_startPos,local_endPos,aabbs)
    if tbl then
        local globalPos = ptwm:apply(pos)
        local distanceSq = (globalPos-startPos):lengthSquared()
        local relative_startPos = local_startPos - pos
        return HitboxRaycastOutput_new{hitbox=self,index=ind, rect=tbl, globalPos = globalPos, localPos = pos, distanceSq = distanceSq, side = side,
            relative_startPos = relative_startPos
            }
    end
end


---disables hitting this
---@param state boolean?
function Hitbox:setDisabled(state)
    self.disabled = state
end


---@alias HasHitbox {hitbox: Hitbox}


-- ---@alias PropertyGetter<T,Y> nil|fun(tbl:T):Y|any

-- ---utility function for getting a property
-- ---@generic T,Y
-- ---@param tbl T
-- ---@param key PropertyGetter<T,Y>
-- ---@return Y|T
-- function Utils.table.getter(tbl,key)
--     if key then
--         if type(key) == "function" then
--             return key(tbl)
--         end
--         return tbl[key]
--     end
--     return tbl
    
-- end


-- raycast:aabb(vec(0,0,0),vec(0,0,1),{{}})


---@generic O: HasHitbox
---@param startPos VectorWorld
---@param endPos VectorWorld
---@param objects { [any] : (Hitbox|O|HasHitbox) }
---@return HitboxRaycastOutput<O?>?
function Hitbox.raycastsOriented(startPos,endPos,objects)
    local out
    local distanceSq = (endPos-startPos):lengthSquared()
    for key, value in pairs(objects) do
        local out1 = (value.hitbox or value):raycastOriented(startPos,endPos)
        if out1 and out1.distanceSq < distanceSq then
            distanceSq = out1.distanceSq
            out = out1
            out.objectKey = key
            out.owner = value.hitbox and value
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



---@generic O
---@param startPos VectorWorld
---@param endPos VectorWorld
---@param hitboxGetter fun(tbl:O):Hitbox? -- if returns nil, is ignored
---@param iterator fun():any, O?
---@param ...any -- rest of the iterator
---@return HitboxRaycastOutput<O>?
function Hitbox.generic_raycastsOriented(startPos,endPos,hitboxGetter,iterator,...)
    local out
    local distanceSq = (endPos-startPos):lengthSquared()

    --- does it work like this?
    for key, value in iterator,... do
        local hitbox = hitboxGetter(value)
        if hitbox then
            local out1 = hitbox:raycastOriented(startPos,endPos)
            if out1 and out1.distanceSq < distanceSq then
                distanceSq = out1.distanceSq
                out = out1
                out.objectKey = key
                out.owner = value
            end
        end
    end
    return out
end



--- a next method that goes through all the hits
---@generic K,O
---@param startPos VectorWorld
---@param endPos VectorWorld
---@param hitboxGetter fun(tbl:O):Hitbox? -- if returns nil, is ignored
---@param next_ fun(...: unknown):K, O?
---@return fun(...: unknown): K, HitboxRaycastOutput<O>?
function Hitbox.raycastsNext(startPos,endPos,hitboxGetter,next_)
    next_ = next_ or next
    hitboxGetter = hitboxGetter or function (t)
        return t.hitbox
    end
    return function (tbl2,index)
        while true do
            local value
            index, value = next_(tbl2,index)
            if index == nil then
                return
            end
            local hitbox = hitboxGetter(value)
            if hitbox then
                local out1 = hitbox:raycastOriented(startPos,endPos)
                if out1 then
                    out1.objectKey = index
                    out1.owner = value
                    return index,out1
                end
            end
        end


    end


    
end





---@alias NestedHasHitbox {hitbox: Hitbox?,children : {[any] : NestedHasHitbox}?}


--- todo
--- closest (currently first) hitbox that got hit while none of its children got hit
---@generic O
---@param startPos VectorWorld
---@param endPos VectorWorld
---@param hitboxGetter fun(tbl:O):Hitbox? -- if returns nil, is ignored
---@param childrenIterator fun(tbl:O):(fun():O?) -- if returns nil, is ignored
---@param root O
---@return HitboxRaycastOutput<O>?
---@return {[O] : HitboxRaycastOutput<O>}
function Hitbox.raycastEnclosure(startPos,endPos,hitboxGetter,childrenIterator,root)

    local n,n2,n3 = childrenIterator(root)
    for key, r in Hitbox.raycastsNext(startPos,endPos,hitboxGetter,n),n2,n3 do

        local q,l = Hitbox.raycastEnclosure(startPos,endPos,hitboxGetter,childrenIterator,r.owner)
        if l then
            l[r.owner] = r
        end
        return q or r, l
    end
    return nil, {}



end



return Hitbox