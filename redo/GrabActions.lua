
require"redo.Grab"

local page = require"redo.ActionWheel2"


local grabKey = keybinds:newKeybind("grab gizmo", "key.mouse.right", false)
local placeKey = keybinds:newKeybind("fix gizmo", "key.mouse.left", false)
local airKey = keybinds:newKeybind("fix gizmo", "key.keyboard.x", false)



function grabKey.press()
    if not player:isLoaded() then return end
        
    local rc2 = Grabbing.raycastLook(Grabbing.Selectable)
    -- logTable(rc2)
    if rc2 then
        Grabbing.rc = rc2
        Grabbing.grab(Grabbing.hitboxToGizmo[rc2.hitbox].partID)
        -- logTable(rc2)
        return true
    end
end


function grabKey.release()
    return Grabbing.release()
end

local Actions = {}

function Actions.putInFront()
    if Grabbing.isGrabbing() then
        AnchorAffix.complex.affixInPlace(Grabbing.carriedPartID,nil,"CarryingPart")
    end
end


function Actions.grabFromList()
    Grabbing.grab(Grabbing.ontoList[Grabbing.ontoIndex])
end

function Actions.releaseToCenter()
    Grabbing.release(nil,true)
end

function Actions.releaseToWorld()
    Grabbing.release("World")
    
end

function Actions.releaseToCoordinate(pos)
    local posID = "!c:" .. Utils.vectorString(pos)
    Utils.ID.from(posID)
    Grabbing.release(posID,true)
end

function Actions.releaseToLook()
    local piv = client.getCameraPos()

    local block, pos, side = raycast:block(piv,piv + client.getCameraDir()*1000)
    Actions.releaseToCoordinate(pos)


end


-- function airKey.press()
--     if Grabbing.isGrabbing() then
--         AnchorAffix.complex.affixInPlace(Grabbing.carriedPartID,nil,"CarryingPart")
--     else
--         Grabbing.grab(Grabbing.ontoList[Grabbing.ontoIndex])
--     end
-- end

-- function placeKey.press()
--     return Grabbing.release("ONTO",true)
-- end


function events.mouse_scroll(dir)
    repeat
        Grabbing.ontoIndex = (Grabbing.ontoIndex - dir - 1) % (math.max(#Grabbing.ontoList,1)) + 1
    until not AnchorAffix.info.isChildOf(Grabbing.ontoList[Grabbing.ontoIndex],Grabbing.carriedPartID)
    Grabbing.updateGUI()
    if Grabbing.isGrabbing() then
        return true
    end
end



page:newAction()
    :title("put in front / grab from list")
    :item("minecraft:stick")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.putInFront)
    :onRightClick(Actions.grabFromList)

page:newAction()
    :title("release to center")
    :item("minecraft:green_wool")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.releaseToCenter)

page:newAction()
    :title("release to world")
    :item("minecraft:iron_block")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.releaseToWorld)
page:newAction()
    :title("release to world")
    :item("minecraft:blaze_rod")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.releaseToLook)