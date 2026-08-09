
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

Grabbing.GUI = models:newPart("GrabbingGUI","GUI"):setPos(-client.getScaledWindowSize().xy_*(0.6))

Grabbing.GUI:newText("text"):setScale(1/2)

  --   local windowScale = client.getScaledWindowSize()/client.getWindowSize()
  --   local mous = client.getMousePos() * windowScale
  --   -- models.model.Item:setPos((-mous):augmented(-10000))


Grabbing.ontoList = {}
Grabbing.ontoIndex = 1
---@type RaycastOutput?
Grabbing.rc = nil


---@param gizmo FloatingObject
function Grabbing.addSelectable(gizmo)
    if not Utils.getID(gizmo) then
        error("adding ID-less object as grabbable: "..printTable(gizmo,1,true))
    end
    Grabbing.Selectable[#Grabbing.Selectable+1] = gizmo
    for key, value in pairs(Positioning.parts) do -- I wonder, the order in which pairs runs is undefined behaviour, so it could lead to desync
        gizmo:createParent(value,key)
    end
end

-- todo: place snapped to grid

-- todo: when grabbing an object, the action wheel is replaced


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


local function colorText(text,color)
    return toJson({"",{text = text, color = color}})

    -- return ('{"text"="%s", color="%s"}'):format(text,color)
end
local function concatColorTexts(lines)
    if #lines == 0 then
        return '[""]'
    end
    return '["", '.. table.concat(lines,", ") .. ']'
end


function Grabbing.updateGUI()
    local text = Grabbing.GUI:getTask("text")
    text:setBackground(true):setBackgroundColor(vec(0x20,0x20,0x10,0x80)/0xFF)
    -- local selected = Grabbing.ontoList[Grabbing.ontoIndex] or "#¤#notpresent"
    -- local start = " | "
    -- local ende = " / "
    ---@type any[]
    local lines = {""}
    
    for index, value in ipairs(Grabbing.ontoList) do
        -- lines[index] = colorText(value.."\n",index == Grabbing.ontoIndex and "#AA0011" or "#FFFFFF")
        lines[#lines+1] = {
            text = value .. "\n",
            color = (index == Grabbing.ontoIndex and "#AA0011" or "#FFFFFF")
        }
    end
    if Grabbing.rc then
        -- lines[#lines+1] = {
        --     text = Utils.vectorString(Grabbing.rc.localPos),
        --     color = "#00FFFF"
        -- }
        lines[#lines+1] = {
            text = printTable(Grabbing.rc,1,true) .. "\n",
            color = "#AAAACA"
        }
        lines[#lines+1] = {
            text = printTable(Grabbing.rc.obj,1,true) .. "\n",
            color = "#AACACA"
        }
        lines[#lines+1] = {
            text = printTable(Utils.getID(Grabbing.rc.obj),1,true) .. "\n",
            color = "#ACAACA"
        }

        
        -- lines[#lines+1] =  colorText(Utils.vectorString(Grabbing.rc.localPos), "#00FFFF")
        -- lines[#lines+1] =  colorText((toJson(Grabbing.rc)), "#00FFFF")
        
    end

    local str = toJson(lines)

    -- local str =  start..table.concat(Grabbing.ontoList,ende.."\n"..start) .. ende
    -- local str1 = str:gsub(start..selected..ende,'"},{"text"="'..start .. selected..ende ..'", color="#4010FF"},{"text"="')
    -- text:setText('["",{"text"="'..str1..'"}]')
    -- text:setText('["",{"text":"Welcome to Minec"},{"text":"raf","color":"dark_green"},{"text":"t Tools"}]')
    text:setText(str)
    
end



local function raycastLook(objects,delta)
    if not player:isLoaded() then return end
        
    local eyePos = entityEyePos(player,delta or client.getFrameTime())
    local dir = player:getLookDir()
    return FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,objects)

end

function grabKey.press()
    if not player:isLoaded() then return end
        
    local rc2 = raycastLook(Grabbing.Selectable)
    if rc2 then

        Grabbing.rc = rc2
        Grabbing.grab(rc2.obj)
        -- logTable(rc2)
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


if host:isHost() then
    events.TICK:register(function ()
        
        if not player:isLoaded() then return end
            
        local rc2 = raycastLook(Grabbing.Selectable)
        Grabbing.rc = rc2
        Grabbing.updateGUI()
    end)
end
