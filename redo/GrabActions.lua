
require"redo.Grab"

local page = require"redo.ActionWheel2"


local grabKey = keybinds:newKeybind("grab gizmo", "key.mouse.right", false)
local placeKey = keybinds:newKeybind("fix gizmo", "key.mouse.left", false)
local airKey = keybinds:newKeybind("fix gizmo", "key.keyboard.x", false)


Grabbing.toggle = true

function grabKey.press()
    if not player:isLoaded() then return end
    if action_wheel:isEnabled() then return end

    if Grabbing.toggle and Grabbing:isGrabbing() then
        return Grabbing.release()
    end
    if Grabbing.disable then return end
        
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
    return (not Grabbing.toggle) and Grabbing.release()
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
    if block then
        Actions.releaseToCoordinate(pos)
    end


end
function Actions.releaseToLookCenter()
    local piv = client.getCameraPos()

    local block, pos, side = raycast:block(piv,piv + client.getCameraDir()*1000)
    if block then
        Actions.releaseToCoordinate(block:getPos())
        return true
    end


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
    local old = Grabbing.ontoIndex
    local control = Grabbing.isGrabbing() and Grabbing.canAffixTo or Grabbing.canGrab
    local selected
    repeat
        Grabbing.ontoIndex = (Grabbing.ontoIndex - dir - 1) % (math.max(#Grabbing.ontoList,1)) + 1
        selected = Grabbing.ontoList[Grabbing.ontoIndex]
    until not (AnchorAffix.info.isChildOf(selected,Grabbing.carriedPartID) or (not control(selected)))
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
    :onScroll(function ()
        local pos = Freecam.Parent():getPositionMatrix():apply(vec(0,0,0))/16
        pos:applyFunc(math.floor)
        pings.part_alter(Freecam.ParentID(),nil,matrices.mat4():translate((pos + 0.5)*16))
    end)

page:newAction()
    :title("release to world / pick freecam parent")
    :item("minecraft:iron_block")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.releaseToWorld)
    :onRightClick(function ()
        Grabbing.grab(Freecam.ParentID())
    end)
page:newAction()
    :title("release to look")
    :item("minecraft:blaze_rod")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(Actions.releaseToLook)
    :onScroll(function ()
        pings.part_alter(Freecam.ParentID(),nil,matrices.mat4():translate(8,8,8))
    end)
    :onRightClick(Actions.releaseToLookCenter)
page:newAction()
    :title("toggle grab UI")
    :item("minecraft:wooden_sword")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function ()
        Grabbing.GUI:setVisible(false)
    end)
    :onRightClick(function ()
        Grabbing.GUI:setVisible(true)
    end)

page:newAction()
    :title("toggle grab")
    :item("minecraft:iron_sword")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function ()
        Grabbing.disable=true
    end)
    :onRightClick(function ()
        Grabbing.disable=false
        
    end)

-- /figura run pings.part_alter("TestObject",nil,matrices.mat4():translate(8,8,8))