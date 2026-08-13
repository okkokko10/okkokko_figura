


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



---@package
Positioning._isActive = {}

---returns true if during the last render this part successfully adjusted itself.
---returns false if it failed
---returns nil if it has not yet run a Positioning function/does not have Positioning
---@param part IDS<ModelPart>
---@return boolean|nil
function Positioning.isActive(part)
    return Positioning._isActive[Utils.ID.materialize(part)]
end

---returns true if the part has run a Positioning function
---@param part IDS<ModelPart>
---@return boolean|nil
function Positioning.isManaged(part)
    return Positioning.isActive(part) ~= nil
end



---@package
---@param part ModelPart
---@param status boolean
---@return nil
function Positioning.setActive(part,status)
    Positioning._isActive[part] = status
end



Positioning.functions = {}


local function materializeEntity(entity)
    if type(entity) == "string" then
        local ent =  (world.getPlayers())[entity]
        if ent then
            return ent, ent:isLoaded()
        else
            return nil, false
        end
    else
        return nil, entity:isLoaded()
    end

end

--- in preRender, as a root World part.
---@param entity Entity
---@param followRot nil|number|"eyes"|"body"
---@return PreRenderFunction
function Positioning.functions.followEntity(entity,followRot)
    if followRot == "eyes" then
        return Positioning.functions.followEntityEyes(entity)
    end
    return function(delta, ctx, part)

        local ent, t = materializeEntity(entity)
        if ent then entity = ent end
        if not t then return Positioning.setActive(part,false) end
        -- root:setPreRender(function (delta,ctx,part) part:setPos(16*(player:getPos(delta))) end)
        part:setPos(PS*(entity:getPos(delta)))
        if followRot then
            if (followRot == "body") then
                part:setRot( 0,-entity:getBodyYaw(delta))
            else
                local rot = entity:getRot(delta)
                part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
            end
            
        end
        Positioning.setActive(part,true)
    end
end

--- in preRender, as a root World part.
---@param entity Entity
---@return PreRenderFunction
function Positioning.functions.followEntityEyes(entity)
    return function(delta, ctx, part)

        local ent, t = materializeEntity(entity)
        if ent then entity = ent end
        if not t then return Positioning.setActive(part,false) end

        local eyePos = Utils.entity.entityEyePos(entity,delta)
        part:setPos(PS*(eyePos))
        local rot = entity:getRot(delta)
        part:setRot(rot.x,-rot.y)
        Positioning.setActive(part,true)
    end
end



---@param entity Entity
---@return PreRenderFunction
function Positioning.functions.followEntityGeneral(entity)
    return function(delta, ctx, part)

        local ent, t = materializeEntity(entity)
        if ent then entity = ent end
        if not t then return Positioning.setActive(part,false) end
        local wtpm = part:getParent():partToWorldMatrix():invert()
        local epos = entity:getPos(delta)
        part:setPos(wtpm:apply(epos))
        Positioning.setActive(part,true)
    end
end

---@type PreRenderFunction
function Positioning.functions._worldRotation(delta, ctx, part)
    local ptwm = part:getParent():partToWorldMatrix()
    local rot = ptwm:deaugmented():scale(PS):invert()
    part:setMatrix(rot:augmented())
    Positioning.setActive(part,true)
end

--- makes it so part:partToWorldMatrix() has identity rotation (up to floating point error) and is positioned at the parent.
---@return PreRenderFunction
function Positioning.functions.worldRotation()
    return Positioning.functions._worldRotation
end




--- moves to the position. moves with sublevels.
---@return PreRenderFunction
function Positioning.functions.coordinate(pos)

    return function(delta, ctx, part)
        
        local mat, loaded = Utils.Sublevel.sublevelPositionMatrix(pos)
        if loaded then
            part:setMatrix(mat)
            Positioning.setActive(part,true)
        else
            Positioning.setActive(part,false)
        end
    end
end


Positioning.make = {}



function Positioning.make.coordinateFollower(pos,name)
    return models:newPart(name or ("follows " ..Utils.vectorString(pos)),"World")
            :setPreRender(Positioning.functions.coordinate(pos))
end


---comment
---@param entity Entity
---@param name any
---@param followRot nil|number|"eyes"|"body"
---@return ModelPart
function Positioning.make.entityFollower(entity,name,followRot)
    return models:newPart(name or entity:getUUID(),"World")
            :setPreRender(Positioning.functions.followEntity(entity,followRot))
end

--- common parts
Positioning.parts = {
    World = models:newPart("World","World"),
}

Positioning.parts.PlayerFollowerEyes = Positioning.make.entityFollower(require"playerValues","PlayerFollowerEyes","eyes")
Positioning.parts.PlayerFollower = Positioning.make.entityFollower(require"playerValues","PlayerFollower")
Positioning.parts.PlayerFollowerYaw = Positioning.make.entityFollower(require"playerValues","PlayerFollowerYaw",1)
Positioning.parts.PlayerFollowerFull = Positioning.make.entityFollower(require"playerValues","PlayerFollowerFull",2)
Positioning.parts.PlayerFollowerBody = Positioning.make.entityFollower(require"playerValues","PlayerFollowerBody","body")

for key, value in pairs(Positioning.parts) do
    Utils.ID.set(value,key)
end



-- returns parent[name].main
function Positioning.make.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setPreRender( Positioning.functions.worldRotation() )
end


function Positioning.make.playerNameFollower(name)
    return Positioning.make.entityFollower(name,"PlayerFollower_"..name)
end

Utils.registerIDConstructor("pl",Positioning.make.playerNameFollower)
Utils.registerIDConstructor("c",function (arg)
    local _, _, x, y, z =  string.find(arg,"^%s*(%S*)%s*(%S*)%s*(%S*)%s*$")
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    if x and y and z then
        return Positioning.make.coordinateFollower(vec(x,y,z))
    end


end)