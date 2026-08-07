


---@class ModelPart
---@field [string] any


---@alias RenderFunction fun(delta:number,ctx:string,part:ModelPart)
---@alias PreRenderFunction RenderFunction
---@alias MidRenderFunction RenderFunction
---@alias PostRenderFunction RenderFunction

----@class FloatingPosition
----@field part ModelPart
Positioning = {}
Positioning.functions = {}

--- in preRender, as a root World part.
---@param entity any
---@param followRot nil|number
---@return PreRenderFunction
function Positioning.functions.followEntity(entity,followRot)
    return function(delta, ctx, part)
        if not entity:isLoaded() then return end
        part:setPos(PS*(entity:getPos(delta)))
        if followRot then
            local rot = entity:getRot(delta)
            part:setRot( (followRot == 2) and rot.x or 0,-rot.y)
        end
    end
end


---@param entity any
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


function Positioning.entityFollower(entity,name,followRot)
    return models:newPart(name or entity:getUUID(),"World")
            :setPreRender(Positioning.functions.followEntity(entity,followRot))
end




-- returns parent[name].main
function Positioning.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setPreRender( Positioning.functions.worldRotation() )
end
