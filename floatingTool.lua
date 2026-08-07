

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







---@class FloatingObject
---@field part ModelPart
---@field modeParents {[any]: ModelPart}
---@field modeStack any[]
FloatingObject = {}


function FloatingObject:new(o)
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      return o
end

function FloatingObject:create(part,modeParents)
    return FloatingObject:new({part=part,modeParents=modeParents,modeStack={}})
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



function FloatingObject.moveToKeepPosParent(part,to)
    local o = to:partToWorldMatrix()
    local p = (part:getParent() or part):partToWorldMatrix()
    part:moveTo(to)
    to:setMatrix(to:getMatrix() * o:invert() * p)
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
function FloatingObject:popMode(index,mode)
    local old = self.modeStack[#self.modeStack]
    if mode and mode ~= old then return end
    self.modeStack[#self.modeStack] = nil
    self:_setMode(self.modeStack[#self.modeStack],old)
    return old
end

function FloatingObject:getParent()
    return self.modeParents[self.modeStack[#self.modeStack]]
end



