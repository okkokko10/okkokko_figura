require"Invoke"


local infoSkull = models:newPart("infoSkull","SKULL")
infoSkull:newItem("infoItem"):setItem("minecraft:blaze_rod")

-- Invoke.infosPart = infoSkull:newPart("infos","World")

local time = 0

Invoke.infosPart = infoSkull:newPart("infos"):setPreRender(
    
    function(delta, ctx, part)
        local nowTime = client.getFrameTime()
        if time == nowTime then
            return true
        end
        time = nowTime
        -- if Invoke.startedSneaking(player) then
        --     log(part,ctx,part:partToWorldMatrix(),part:getParent():partToWorldMatrix(),matrices.mat4():scale(1/16))
        -- end
        -- if not player:isLoaded() then return end
        part:setMatrix(part:getParent():partToWorldMatrix():invert()*matrices.mat4():scale(1/16))
        return true

    end
)

