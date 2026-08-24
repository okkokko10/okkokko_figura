require"invoke.Invoke"


local infoSkull = models:newPart("infoSkull","SKULL")
infoSkull:newItem("infoItem"):setItem("minecraft:player_head[minecraft:profile={name:okkokko}]"):setPos(0,8,0)
local infoSkullText = infoSkull:newText("infoText"):setText("okkokko's skull"):setPos(0,8,-5):setScale(0.25):setAlignment("CENTER")

events.WORLD_TICK:register(function (delta)
    infoSkullText:setText(("okkokko's skull\n%s\n%s"):format(client.getFrameTime() or "", world.getTime()))
end)


-- Invoke.infosPart = infoSkull:newPart("infos","World")

local time = 0

Invoke.infosPart = infoSkull:newPart("infos"):setPreRender(
    
    function(delta, ctx, part)
        --- this should make it so infos are only drawn once
        local nowTime = client.getFrameTime()
        if time == nowTime then
            part.root:setVisible(false)
            return true
        else
            part.root:setVisible(true)
        end
        time = nowTime

        -- if Invoke.startedSneaking(player) then
        --     log(part,ctx,part:partToWorldMatrix(),part:getParent():partToWorldMatrix(),matrices.mat4():scale(1/16))
        -- end
        -- if not player:isLoaded() then return end
        part:setMatrix(part:getParent():partToWorldMatrix():invert()*matrices.mat4():scale(1/16))
        return true

    end
):newPart("root")

