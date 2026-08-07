

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

---@class FloatingObject
---@field part ModelPart
---@field modeParents {[any]: ModelPart}
---@field modeStack any[]
---@field hitboxes {[any]: Hitbox}
FloatingObject = {}


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

function FloatingObject:_setMode(mode,oldMode)
    local m = self.modeParents[mode]
    self.part:moveTo(m.part or m)
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


function FloatingObject:_setModeKeepPos(mode,oldMode)
    local m = self.modeParents[mode]
    local mm = m.part or m
    FloatingObject.moveToKeepPos(self.part,mm)
end

function FloatingObject:_setModeKeepPosParent(mode,oldMode)
    local m = self.modeParents[mode]
    local mm = m.part or m
    FloatingObject.moveToKeepPosParent(self.part,mm)
end


function FloatingObject:pushMode(mode)
    self.modeStack[#self.modeStack+1] = mode
    self:_setMode(mode,self.modeStack[#self.modeStack-1])
    return self
    -- return #self.modeStack
end

function FloatingObject:pushModeKeepPos(mode)
    self.modeStack[#self.modeStack+1] = mode
    self:_setModeKeepPosParent(mode,self.modeStack[#self.modeStack-1])
    return self
    -- return #self.modeStack
end


function FloatingObject:popMode(index,mode)
    local old = self.modeStack[#self.modeStack]
    if (mode and mode ~= old) or #self.modeStack <= 1 then return end
    self.modeStack[#self.modeStack] = nil
    self:_setMode(self.modeStack[#self.modeStack],old)
    return old
end

function FloatingObject:getParent()
    return self.modeParents[self.modeStack[#self.modeStack]]
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

-- log(raycast:aabb(vec(0,0,0), vec(0,0,1), {{-vec(1,1,1),vec(1,1,1)}}))

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
    self:pushModeKeepPos(name or p)
end

function FloatingObject:changePos(change)
    local par = self.part:getParent()
    local d = par:getParent():partToWorldMatrix():invert():applyDir(change)
    -- log(d,par:getPos(),par:getPositionMatrix())
    par:setMatrix(par:getPositionMatrix():translate(d))
    -- par:setPos(par:getPos() + d)
end

