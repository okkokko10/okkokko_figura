

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

local debugKey = keybinds:newKeybind("debug log", "key.keyboard.j")



-- returns parent[name].main
function FloatingPosition.absoluteRot(name,parent)
    return (parent or models):newPart(name)
        :setPreRender( -- midRender so that the partToWorldMatrix is updated, hopefully the children's matrices haven't yet
            function(delta, ctx, part)
                local ptwm = part:getParent():partToWorldMatrix()
                local rot = ptwm:deaugmented():invert():scale(1/16)
                part:setMatrix(rot:augmented())
            end
        )
end
