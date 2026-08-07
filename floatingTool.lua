

-- objects that can follow the player but can be repositioned.
-- includes objects having multiple modes, and a state where objects briefly take on a certain mode, going back afterwards
-- follow player, with rotation, with head rotation
-- player mode where rotation is not registered so you can reach objects behind you
-- clicking objects with the mouse
-- go into freecam with any object
-- an object should have a "menu" state where it is in front of the player/camera so they can choose it.
-- maybe a gui

-- maybe a "table"
-- ooh, physics for objects on the table?

-- there are tools, and there are positions.


-- idea: Outer Wilds Projection Pools





---@class Hitbox
---@field pos vec3
---@field size number

---@class FloatingObject: IdUtil<FloatingObject>
---@field part ModelPart
---@field modeParents {[any]: ModelPart}
---@field modeStack any[]
---@field hitboxes {[any]: Hitbox}
FloatingObject = {}

require("utils")._registerIDChaining(FloatingObject)

function FloatingObject:new(o)
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      return o
end

---@return FloatingObject
function FloatingObject:create(part,modeParents)
    return FloatingObject:new({part=part,modeParents=modeParents,modeStack={},hitboxes={}}):pushMode("base")
end


function FloatingObject.toPart(o)
    return o.part or o
end

function FloatingObject:getModeParent(mode)
    return self.modeParents[mode] or FloatingObject.fromID(mode) or mode
end


function FloatingObject.moveToKeepPos(part,to)
    local o = to:partToWorldMatrix()
    local p = part:partToWorldMatrix()
    part:moveTo(to)
    part:setMatrix(o:invert() * p)
end



function FloatingObject.moveToKeepPosParent2(part,to)
    local o = to:getParent():partToWorldMatrix()
    local p = (part:getParent() or part):partToWorldMatrix()
    part:moveTo(to)
    to:setMatrix(o:invert() * p)
end

function FloatingObject.moveToKeepPosParent(part,to)
    local o = to:partToWorldMatrix()
    local p = (part:getParent() or part):partToWorldMatrix()
    part:moveTo(to)
    to:setMatrix(to:getPositionMatrix() * o:invert() * p)
end

function FloatingObject._make_setMode(moveTo)
    return function (self,mode,oldMode,doPing)
        moveTo(self.part,FloatingObject.toPart(self:getModeParent(mode)))
    end
end

FloatingObject._setMode = FloatingObject._make_setMode(models.moveTo)
-- function FloatingObject:_setMode(mode,oldMode)
--     local m = self:getModeParent(mode)
--     self.part:moveTo(m.part or m)
-- end

FloatingObject._setModeKeepPos = FloatingObject._make_setMode(FloatingObject.moveToKeepPos)
-- function FloatingObject:_setModeKeepPos(mode,oldMode)
--     local m = self:getModeParent(mode)
--     local mm = m.part or m
--     FloatingObject.moveToKeepPos(self.part,mm)
-- end

FloatingObject._setModeKeepPosParent = FloatingObject._make_setMode(FloatingObject.moveToKeepPosParent)
-- function FloatingObject:_setModeKeepPosParent(mode,oldMode)
--     local m = self:getModeParent(mode)
--     local mm = m.part or m
--     FloatingObject.moveToKeepPosParent(self.part,mm)
-- end

-- if mode is a local mode string, use it as is, otherwise look if it's a global id, and if so, use its value. otherwise use it as is (in this case it should be a part.)

function FloatingObject._make_pushMode(setMode)
    return function (self,mode,doPing)
        local mode1 = (not self.modeParents[mode]) and FloatingObject.getID(mode) or mode
        self.modeStack[#self.modeStack+1] = mode1
        setMode(self,mode1,self.modeStack[#self.modeStack-1])
        return self
    end
end
FloatingObject.pushMode = FloatingObject._make_pushMode(FloatingObject._setMode)
-- function FloatingObject:pushMode(mode)
--     self.modeStack[#self.modeStack+1] = mode
--     self:_setMode(mode,self.modeStack[#self.modeStack-1])
--     return self
--     -- return #self.modeStack
-- end

FloatingObject.pushModeKeepPosParent = FloatingObject._make_pushMode(FloatingObject._setModeKeepPosParent)
-- function FloatingObject:pushModeKeepPos(mode)
--     self.modeStack[#self.modeStack+1] = mode
--     self:_setModeKeepPosParent(mode,self.modeStack[#self.modeStack-1])
--     return self
--     -- return #self.modeStack
-- end


function FloatingObject._make_popMode(setMode)
    ---@param self FloatingObject
    ---@param mode any?
    ---@param index number?
    return function (self,mode,index)
        local old = self.modeStack[#self.modeStack]
        if (mode and mode ~= old) or #self.modeStack <= 1 then return end
        self.modeStack[#self.modeStack] = nil
        setMode(self,self.modeStack[#self.modeStack],old)
        return old
    end
end


FloatingObject.popMode = FloatingObject._make_popMode(FloatingObject._setMode)
-- function FloatingObject:popMode(mode,index)
--     local old = self.modeStack[#self.modeStack]
--     if (mode and mode ~= old) or #self.modeStack <= 1 then return end
--     self.modeStack[#self.modeStack] = nil
--     self:_setMode(self.modeStack[#self.modeStack],old)
--     return old
-- end
FloatingObject.popModeKeepPosParent = FloatingObject._make_popMode(FloatingObject._setModeKeepPosParent)


function FloatingObject:getParent()
    return self:getModeParent(self.modeStack[#self.modeStack])
end

--- adds an AABB at the part
function FloatingObject:addHitbox(pos,size,name)
    self.hitboxes[name or (#self.hitboxes+1)] = {pos=pos,size=size}
    return self
end

function FloatingObject:getAABBs(out)
    local ptwm = self.part:partToWorldMatrix()
    out = out or {}
    for key, cube in pairs(self.hitboxes) do
        local pos = ptwm:apply(cube.pos*PS)
        out[#out+1] = {pos-cube.size/2,pos+cube.size/2, key=key,obj = self}
    end
    return out
end

function FloatingObject:getAABBsO(out)
    -- local ptwm = self.part:partToWorldMatrix()
    out = out or {}
    for key, cube in pairs(self.hitboxes) do
        -- local pos = ptwm:apply(cube.pos*PS)
        out[#out+1] = {(cube.pos-cube.size/2)*PS,(cube.pos+cube.size/2)*PS, key=key,obj = self}
    end
    return out
end
-- log(raycast:aabb(vec(0,0,0), vec(0,0,1), {{-vec(1,1,1),vec(1,1,1)}}))


---@class RaycastOutput
---@field obj FloatingObject
---@field hitboxKey any
---@field globalPos vec3
---@field localPos vec3
---@field distanceSq number
---@field side string?

local debugKey = keybinds:newKeybind("debug", "key.keyboard.j")

---comment
---@param startPos vec3
---@param endPos vec3
---@return RaycastOutput?
function FloatingObject:raycastOriented(startPos,endPos)
    local ptwm = self.part:partToWorldMatrix()
    local wtpm = ptwm:inverted()
    local aabbs = self:getAABBsO()
    local tbl,pos,side,ind = raycast:aabb(wtpm:apply(startPos),wtpm:apply(endPos),aabbs)
    -- if debugKey:isPressed() then
    --     log(tbl,pos,side,ind,wtpm:apply(startPos),startPos)
    --     logTable(aabbs,2)
    --     log(wtpm)
    -- end
    if tbl then
        local globalPos = ptwm:apply(pos)
        local distanceSq = (globalPos-startPos):lengthSquared()
        -- return tbl.obj,tbl.key,globalPos,pos,distanceSq,side
        return {obj = tbl.obj,hitboxKey = tbl.key,globalPos = globalPos,localPos = pos,distanceSq = distanceSq,side = side}

    end
end




---comment
---@param startPos vec3
---@param endPos vec3
---@param objects FloatingObject[]
---@return RaycastOutput?
function FloatingObject.raycastsOriented(startPos,endPos,objects)
    local out
    local distanceSq = (endPos-startPos):lengthSquared()*16
    for key, value in pairs(objects) do
        local out1 = value:raycastOriented(startPos,endPos)
        if out1 and out1.distanceSq < distanceSq then
            distanceSq = out1.distanceSq
            out = out1
        end
    end
    return out
end



---comment
---@param startPos vec3
---@param endPos vec3
---@param objects FloatingObject[]
function FloatingObject.raycast(startPos,endPos,objects)
    local aabbs = {}
    for key, value in pairs(objects) do
        value:getAABBs(aabbs)
    end
    local tbl,pos,side,ind = raycast:aabb(startPos,endPos,aabbs)
    if tbl then
        return tbl.obj,tbl.key,pos,side
    end
end


function FloatingObject:createParentInPlace(root,name)
    local p = (root or Positioning.parts.World):newPart(name or "unnamed")
    -- log(p:partToWorldMatrix())
    self.modeParents[name or p] = p
    self:pushModeKeepPosParent(name or p)
end

function FloatingObject:changePos(change)
    local par = self.part:getParent()
    local d = par:getParent():partToWorldMatrix():invert():applyDir(change)
    -- log(d,par:getPos(),par:getPositionMatrix())
    par:setMatrix(par:getPositionMatrix():translate(d))
    -- par:setPos(par:getPos() + d)
end
