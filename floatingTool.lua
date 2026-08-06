

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



local PlayerValues = {
    ---@type vec3?
    pos = nil,
    rot = nil,
}

function PlayerValues:isLoaded()
    return player:isLoaded()
end
function PlayerValues:getPos(delta)
    -- if not player:isLoaded() then return end
    return PlayerValues.pos or player:isLoaded() and player:getPos(delta)
end
function PlayerValues:getRot(delta)
    -- if not player:isLoaded() then return end
    return PlayerValues.rot or player:isLoaded() and player:getRot(delta)
end
function PlayerValues:getUUID()
    -- if not player:isLoaded() then return end
    return player:getUUID()
end






---@class FloatingObject
---@field part ModelPart
---@field modeParents {[any]: FloatingPosition|ModelPart}
---@field modeStack any[]
local FloatingObject = {}


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





---@class ModelPart
---@field [string] any

---@class FloatingPosition
---@field part ModelPart
local FloatingPosition = {}


function FloatingPosition:new(o)
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      return o
end


function FloatingPosition.entityFollower(entity,name,followRot)
    return models:newPart(name or entity:getUUID(),"World")
            :setPreRender(
            function(delta, ctx, part)
                if not entity:isLoaded() then return end
                part:setPos(PS*(entity:getPos(delta)))
                if followRot then
                    local rot = entity:getRot(delta)
                    part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
                end
            end
        )
    -- FloatingPosition:new({
    --     part = 
    --         models:newPart(name,"World")
    --         :setPreRender(
    --         function(delta, ctx, part)
    --             if not entity:isLoaded() then return end
    --             part:setPos(PS*(entity:getPos(delta)))
    --         end
    --     )
    --     })
end

-- local debugKey = keybinds:newKeybind("debug log", "key.keyboard.j")



-- returns parent[name].main
function FloatingPosition.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setMidRender( -- midRender so that the partToWorldMatrix is updated, hopefully the children's matrices haven't yet
            function(delta, ctx, part)
                local ptwm = part:partToWorldMatrix()
                local rot = ptwm:deaugmented():augmented():invert() -- the invert can be done faster inside
                part.main:setMatrix(rot)
            end
        ):newPart("main")
        :setPostRender(
            function(delta, ctx, part)
                local ptwm = part:partToWorldMatrix()
                -- if debugKey:isPressed() then
                --     log(ptwm)
                -- end
            end
        )
    
end




Objects = {}
Objects.PlayerFollow = FloatingPosition.entityFollower(PlayerValues,"PlayerFollow", 2)

-- Objects.PlayerFollow = models:newPart("PlayerFollow","World")
--     :setPreRender(
--       function(delta, ctx, part)
--         if not player:isLoaded() then return end
--         part:setPos(PS*(PlayerValues.getPos(delta)))
--       end
--     )
Objects.World = models:newPart("World","World")


TestObject = FloatingObject:create(models:newPart("TestObject","LEFT_ITEM_PIVOT"),
    {
        base = Objects.PlayerFollow:newPart("TestObjectP1"):setPos(PS*2,PS/2,0),
    }):pushMode("base")

TestObject.part:newItem("Item"):setItem("minecraft:glass")
-- TestObject.part:addChild(vanilla_model.PLAYER)
TestCompass = FloatingPosition.absoluteRot("wa",TestObject.part)
TestCompass:newItem("Item"):setItem("minecraft:green_stained_glass"):setScale(1/16)