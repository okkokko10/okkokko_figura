--- by okkokko
--- 
--- hold E to begin and move forward.
--- press shift-E to return to normal vision
--- press ctrl-E to move freecam back to the player position
do return end --- REMOVE THIS LINE TO USE



local Freecam = {}

Freecam.speed = 20

--- YOU CAN CHANGE THIS
local freecamKey = keybinds:newKeybind("move freecam 2", "key.keyboard.e", false)


function Freecam.isMoving()
    return freecamKey:isPressed()
end




function freecamKey.press(bitmask)
    if bitmask == 0 then
        Freecam.activate()
    elseif bitmask == 1 then
        Freecam.deactivate()
    else
        Freecam.reset_pos()
        Freecam.deactivate()
    end
end

--- you don't need to modify stuff beyond this, but you may call the functions from elsewhere

Freecam.active = false

function Freecam.activate()
    Freecam.active = true
end

function Freecam.deactivate()
    renderer:setCameraPivot()
    Freecam.active = false
end

function Freecam.reset_pos()
    
    if not player:isLoaded() then
        Freecam.pos = nil
        return
    end
    Freecam.pos = (player:getPos() + vec(0,2,0))
end



if host:isHost() then
    events.WORLD_RENDER:register(function (delta)
        if not player:isLoaded() then return end
        if Freecam.active then
            if Freecam.pos then
            renderer:setCameraPivot(Freecam.pos)
                
            end
            if Freecam.isMoving() then
                local change = player:getLookDir() * (Freecam.speed / (client.getFPS()+1))
                Freecam.pos = (Freecam.pos or (player:getPos(delta) + vec(0,2,0))) + change
            end
        end
        
        
    end)
end

return Freecam