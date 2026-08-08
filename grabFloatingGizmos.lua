
require"floatingTool"
require"positioning"
require"utils"
require"kineticsPath"



local grabKey = keybinds:newKeybind("grab gizmo", "key.mouse.right", false)
local placeKey = keybinds:newKeybind("fix gizmo", "key.mouse.left", false)


local carryingPart = Utils.setID(Positioning.parts.PlayerFollowerEyes:newPart("CarryingPart"),"CarryingPart")



Grabbing = {}

---@type FloatingObject
Grabbing.carriedObject = nil

Grabbing.Selectable = {}

Grabbing.GUI = models:newPart("GrabbingGUI","GUI")

Grabbing.GUI:newText("text"):setText(("GUI----------------------\n-----------------\n----------"):rep(5))

  --   local windowScale = client.getScaledWindowSize()/client.getWindowSize()
  --   local mous = client.getMousePos() * windowScale
  --   -- models.model.Item:setPos((-mous):augmented(-10000))

Grabbing.GUI:setPos(-client.getScaledWindowSize()._y_/2)

Grabbing.ontoList = {}
Grabbing.ontoIndex = 1


---@param gizmo FloatingObject
function Grabbing.addSelectable(gizmo)
    Grabbing.Selectable[#Grabbing.Selectable+1] = gizmo
    for key, value in pairs(Positioning.parts) do -- I wonder, the order in which pairs runs is undefined behaviour, so it could lead to desync
        gizmo:createParent(value,key)
    end
end

-- todo: place snapped to grid


function Grabbing.isGrabbing()
    return not not Grabbing.carriedObject
end

---comment
---@param gizmo FloatingObject
function Grabbing.grab(gizmo)
    if Grabbing.isGrabbing() then return end
    Grabbing.carriedObject = gizmo
    Grabbing.carriedObject:pushModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
    Grabbing.ontoList = {}
    for key, value in pairs(gizmo.modeParents) do
        if type(key)=="string" or type(key)=="number" then
            Grabbing.ontoList[#Grabbing.ontoList+1] = key
            if key == gizmo.modeStack[#gizmo.modeStack-1] then
                Grabbing.ontoIndex = #Grabbing.ontoList
            end
            
        end
    end
    -- log(gizmo.modeStack[#gizmo.modeStack-1])
    host:swingArm(true)
    Grabbing.updateGUI()

end

--- note: this will continuously add onto the stack
function Grabbing.release(onto)
    if Grabbing.isGrabbing() then
        if onto == "ONTO" or true then
            onto = Grabbing.ontoList[Grabbing.ontoIndex]
        end
        if onto then
            local nex = onto
            Grabbing.carriedObject:swapModeKeepPosParent(nex,("CarryingPart") --[[@as ID<ModelPart>]],true)
        else
            Grabbing.carriedObject:popModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
        end
        Grabbing.carriedObject = nil
        host:swingArm(true)
        Grabbing.ontoList = {}
        Grabbing.updateGUI()
        return true
    end
end


function Grabbing.updateGUI()
    local text = Grabbing.GUI:getTask("text")
    local selected = Grabbing.ontoList[Grabbing.ontoIndex] or "#¤#"
    local start = " | "
    local ende = " / "
    local str =  start..table.concat(Grabbing.ontoList,ende.."\n"..start) .. ende
    local str1 = str:gsub(start..selected..ende,'"},{"text"="'..start .. selected..ende ..'", color="#4010FF"},{"text"="')
    text:setText('["",{"text"="'..str1..'"}]')
    -- text:setText('["",{"text":"Welcome to Minec"},{"text":"raf","color":"dark_green"},{"text":"t Tools"}]')
    -- text:setText()
    
end


function grabKey.press()
    if not player:isLoaded() then return end
        
    local eyePos = entityEyePos(player,delta)
    local dir = player:getLookDir()
    -- local rc = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,tabletButtons)
    -- if rc then
    --     -- rc.obj
    -- end

    local rc2 = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,Grabbing.Selectable)
    if rc2 then
        Grabbing.grab(rc2.obj)
        return true
    end
end

function grabKey.release()
    return Grabbing.release()
end


function placeKey.press()
    return Grabbing.release("ONTO")
end

function events.mouse_scroll(delta)
    -- log(delta)
    if Grabbing.isGrabbing() then
        Grabbing.ontoIndex = (Grabbing.ontoIndex - delta - 1) % (math.max(#Grabbing.ontoList,1)) + 1
        Grabbing.updateGUI()
        return true
    end
end
