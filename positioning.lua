


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
        local b = entity:getPos(delta)
        if b then
            part:setPos(PS*b)
        end
        if followRot then
            if (followRot == "body") then
                local a = entity:getBodyYaw(delta)
                if a then
                    part:setRot( 0,-a)
                end
            else
                local rot = entity:getRot(delta)
                if rot then
                    part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
                end
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
        if eyePos then
            part:setPos(PS*(eyePos))
        end
        local rot = entity:getRot(delta)
        if rot then
            part:setRot(rot.x,-rot.y)
        end
        Positioning.setActive(part,true)
    end
end


--- in preRender, as a root World part.
---@param entity Entity
---@param followRot nil|number|"eyes"|"body"
---@return PreRenderFunction
function Positioning.functions.followEntityRot(entity,followRot)
    if followRot == "eyes" then
        return Positioning.functions.followEntityEyes(entity)
    end
    return function(delta, ctx, part)

        local ent, t = materializeEntity(entity)
        if ent then entity = ent end
        if not t then return Positioning.setActive(part,false) end
        
        if (followRot == "body") then
            local a = entity:getBodyYaw(delta)
            if a then
                part:setRot( 0,-a)
            end
        else
            local rot = entity:getRot(delta)
            if rot then
                part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
            end
        end
            
        
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

---@type {[Vector] : {old?: Matrix, current: Matrix, loaded: boolean}}
Positioning._CoordinateMatrices = {}


--- moves to the position. moves with sublevels.
--- lerps matrices, which is not ideal.
---@return fun() world_tick_function
---@return PreRenderFunction
function Positioning.functions.coordinate(pos)
    -- local matri = matrices.mat4()
    -- local oldMatri = matri
    -- local loaded = false
    if not Positioning._CoordinateMatrices[pos] then
        Positioning._CoordinateMatrices[pos] = {current = matrices.mat4()}
    end
    return function()
        local cm = Positioning._CoordinateMatrices[pos]
        cm.old = cm.current
        cm.current, cm.loaded = Utils.Sublevel.sublevelPositionMatrix(pos)
        if not cm.loaded then
            cm.current = cm.old
        end
    end, function (delta, ctx, part)
        local cm = Positioning._CoordinateMatrices[pos]
        if cm and cm.loaded then
            local mat = math.lerp(cm.old or cm.current,cm.current,delta)
            part:setMatrix(mat)
            Positioning.setActive(part,true)
        else
            Positioning.setActive(part,false)
        end
    end
end


Positioning.make = {}



function Positioning.make.coordinateFollower(pos,name,parent)
    local nm = name or ("follows " ..Utils.vectorString(pos))
    local onTick, onPreRender = Positioning.functions.coordinate(pos)
    local tick_name = "tick_coordinate_" .. tostring(pos)
    if events.WORLD_TICK:getRegisteredCount(tick_name) == 0 then
        events.WORLD_TICK:register(onTick,tick_name)
    end
    return (parent or models):newPart(nm)
        :setPreRender(onPreRender)
end


---comment
---@param entity Entity
---@param name any
---@param followRot nil|number|"eyes"|"body"
---@param onlyRot boolean?
---@return ModelPart
function Positioning.make.entityFollower(entity,name,followRot,onlyRot)
    return models:newPart(name or entity:getUUID(),"World")
            :setPreRender((onlyRot and Positioning.functions.followEntityRot or Positioning.functions.followEntity)(entity,followRot))
end

--- common parts
Positioning.parts = {
    World = models:newPart("World","World"),
}

Utils.ID.field.FollowMe = (models:newPart("player root","World"))

Positioning.parts.PlayerFollowerEyes = Positioning.make.entityFollower(require"playerValues","PlayerFollowerEyes","eyes"):moveTo(Utils.ID.field.FollowMe)
Positioning.parts.PlayerFollower = Positioning.make.entityFollower(require"playerValues","PlayerFollower"):moveTo(Utils.ID.field.FollowMe)
Positioning.parts.PlayerFollowerYaw = Positioning.make.entityFollower(require"playerValues","PlayerFollowerYaw",1):moveTo(Utils.ID.field.FollowMe)
Positioning.parts.PlayerFollowerFull = Positioning.make.entityFollower(require"playerValues","PlayerFollowerFull",2):moveTo(Utils.ID.field.FollowMe)
Positioning.parts.PlayerFollowerBody = Positioning.make.entityFollower(require"playerValues","PlayerFollowerBody","body"):moveTo(Utils.ID.field.FollowMe)



Positioning.parts.Disabled = Utils.ID.field.FollowMe:newPart("Disabled"):setVisible(false)

Positioning.parts.MyBase = Positioning.parts.Disabled:newPart("MyBase"):setPos(0,PS*3,0)



for key, value in pairs(Positioning.parts) do
    Utils.ID.set(value,key)
end



-- returns parent[name].main
function Positioning.make.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setPreRender( Positioning.functions.worldRotation() )
end


--- todo: these should be unselectable in the grab UI

require"redo.GrabAttributes"
GrabAttributes.pl.unselectable = true
Utils.ID.field.pl = (models:newPart("player root","World"))



function Positioning.make.playerNameFollower(name)
    return Positioning.make.entityFollower(name,"PlayerFollower_"..name):moveTo(Utils.ID.field.pl)
end
Utils.registerIDConstructor("pl",Positioning.make.playerNameFollower)

GrabAttributes.c.unselectable = true
Utils.ID.field.c = (models:newPart("player root","World"))

Utils.registerIDConstructor("c",function (arg)
    local _, _, x, y, z =  string.find(arg,"^%s*(%S*)%s*(%S*)%s*(%S*)%s*$")
    x = tonumber(x)
    y = tonumber(y)
    z = tonumber(z)
    if x and y and z then
        return Positioning.make.coordinateFollower(vec(x,y,z)):moveTo(Utils.ID.field.c)
    end


end)