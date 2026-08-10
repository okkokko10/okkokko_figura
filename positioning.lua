


---@class ModelPart : HasGetSetScalePos
---@field newPart fun(...): ModelPart
---@field [string] any|(fun(...):ModelPart)|fun(...):any
---@field ["moveTo"|"setMatrix"|"setPos"|"setRot"|"setScale"] fun(...): ModelPart
---@field partToWorldMatrix fun(self:self):Matrix

---@alias RenderFunction fun(delta:number,ctx:string,part:ModelPart)
---@alias PreRenderFunction RenderFunction
---@alias MidRenderFunction RenderFunction
---@alias PostRenderFunction RenderFunction

----@class FloatingPosition
----@field part ModelPart
Positioning = {}
Positioning.functions = {}

--- in preRender, as a root World part.
---@param entity Entity
---@param followRot nil|number|"eyes"|"body"
---@return PreRenderFunction
function Positioning.functions.followEntity(entity,followRot)
    if followRot == "eyes" then
        return Positioning.functions.followEntityEyes(entity)
    end
    return function(delta, ctx, part)
        if not entity:isLoaded() then return end
        part:setPos(PS*(entity:getPos(delta)))
        if followRot then
            if (followRot == "body") then
                part:setRot( 0,-entity:getBodyYaw(delta))
            else
                local rot = entity:getRot(delta)
                part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
            end
            
        end
    end
end

--- in preRender, as a root World part.
---@param entity Entity
---@return PreRenderFunction
function Positioning.functions.followEntityEyes(entity)
    return function(delta, ctx, part)
        if not entity:isLoaded() then return end
        local eyePos = entityEyePos(entity,delta)
        part:setPos(PS*(eyePos))
        local rot = entity:getRot(delta)
        part:setRot(rot.x,-rot.y)
    end
end



---@param entity Entity
---@return PreRenderFunction
function Positioning.functions.followEntityGeneral(entity)
    return function(delta, ctx, part)
        if not entity:isLoaded() then return end
        local wtpm = part:getParent():partToWorldMatrix():invert()
        local epos = entity:getPos(delta)
        part:setPos(wtpm:apply(epos))
    end
end

---@type PreRenderFunction
function Positioning.functions._worldRotation(delta, ctx, part)
    local ptwm = part:getParent():partToWorldMatrix()
    local rot = ptwm:deaugmented():scale(PS):invert()
    part:setMatrix(rot:augmented())
end

--- makes it so part:partToWorldMatrix() has identity rotation (up to floating point error) and is positioned at the parent.
---@return PreRenderFunction
function Positioning.functions.worldRotation()
    return Positioning.functions._worldRotation
end

--- common parts
Positioning.parts = {
    World = models:newPart("World","World"),
}

---comment
---@param entity Entity
---@param name any
---@param followRot nil|number|"eyes"|"body"
---@return ModelPart
function Positioning.entityFollower(entity,name,followRot)
    return models:newPart(name or entity:getUUID(),"World")
            :setPreRender(Positioning.functions.followEntity(entity,followRot))
end

Positioning.parts.PlayerFollowerEyes = Positioning.entityFollower(require"playerValues","PlayerFollowerEyes","eyes")
Positioning.parts.PlayerFollower = Positioning.entityFollower(require"playerValues","PlayerFollower")
Positioning.parts.PlayerFollowerYaw = Positioning.entityFollower(require"playerValues","PlayerFollowerYaw",1)
Positioning.parts.PlayerFollowerFull = Positioning.entityFollower(require"playerValues","PlayerFollowerFull",2)
Positioning.parts.PlayerFollowerBody = Positioning.entityFollower(require"playerValues","PlayerFollowerBody","body")

for key, value in pairs(Positioning.parts) do
    Utils.setID(value,key)
end



-- returns parent[name].main
function Positioning.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setPreRender( Positioning.functions.worldRotation() )
end
