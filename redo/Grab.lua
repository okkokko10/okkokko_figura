
require".positioning"
require".utils"
local AnchorAffix = require"./AnchorAffix"


-- do return end

local grabKey = keybinds:newKeybind("grab gizmo", "key.mouse.right", false)
local placeKey = keybinds:newKeybind("fix gizmo", "key.mouse.left", false)
local airKey = keybinds:newKeybind("fix gizmo", "key.keyboard.x", false)




local carryingPart = Utils.setID(Positioning.parts.PlayerFollowerEyes:newPart("CarryingPart"),"CarryingPart")



Grabbing = {}

---@type ID<ModelPart>?
Grabbing.carriedPartID = nil

---@type HasPartIDHitbox[]
Grabbing.Selectable = {}

-- function Grabbing.addSelectable(gizmo) end

Grabbing.GUI = models:newPart("GrabbingGUI2","GUI"):setPos(-client.getScaledWindowSize().xy_*vec(1,0.3,1))

Grabbing.GUI:newText("text"):setAlignment("RIGHT") --:setScale(1/2)

  --   local windowScale = client.getScaledWindowSize()/client.getWindowSize()
  --   local mous = client.getMousePos() * windowScale
  --   -- models.model.Item:setPos((-mous):augmented(-10000))


---@type ID<ModelPart>[]
Grabbing.ontoList = {}
Grabbing.ontoIndex = 1
---@type HitboxRaycastOutput?
Grabbing.rc = nil
Grabbing.hitboxToGizmo = {}

---@class HasPartID
---@field partID ID<ModelPart>


---@class HasHitbox
---@field hitbox Hitbox

---@class HasPartIDHitbox: HasPartID, HasHitbox



--- TODO: the GUI should show the grabbable things in a hierarchy.


-- for key, value in pairs(Positioning.parts) do -- I wonder, the order in which pairs runs is undefined behaviour, so it could lead to desync
--     Grabbing2.ontoList[#Grabbing2.ontoList+1] =
-- end

---@param gizmo HasPartIDHitbox
function Grabbing.addSelectable(gizmo)
    if not Utils.fromID(gizmo.partID,"ModelPart") then
        error("adding ID-less object as grabbable: "..printTable(gizmo,1,true)) -- the error would have already happened
    end
    Grabbing.Selectable[#Grabbing.Selectable+1] = gizmo
    Grabbing.hitboxToGizmo[gizmo.hitbox] = gizmo
    -- for key, value in pairs(Positioning.parts) do -- I wonder, the order in which pairs runs is undefined behaviour, so it could lead to desync
    --     gizmo:createParent(value,key)
    -- end
end

-- todo: place snapped to grid

-- todo: when grabbing an object, the action wheel is replaced
-- todo: when looking at an object, its parent is highlighted.



---sets ontoList as the list of IDd ModelParts
function Grabbing.updateOntoList()
    Grabbing.ontoList = {}
    Grabbing.ontoListInv = {}
    for id, value in pairs(Utils.listIDd()) do
        if type(value) == "ModelPart" and id ~= "CarryingPart" then
            Grabbing.ontoList[#Grabbing.ontoList+1] = id
            Grabbing.ontoListInv[id] = #Grabbing.ontoList
        end
    end
end

function Grabbing.isGrabbing()
    return not not Grabbing.carriedPartID
end

---comment
---@param partID ID<ModelPart>
function Grabbing.grab(partID)
    if Grabbing.isGrabbing() or not Utils.fromID(partID) then return end
    Grabbing.carriedPartID = partID
    local parentID = AnchorAffix.info.getParentID(partID)
    Grabbing.updateOntoList()
    Grabbing.ontoIndex = Grabbing.ontoListInv[parentID] or 1
    AnchorAffix.complex.affixInPlace(partID,"CarryingPart")


    -- Grabbing2.carriedObject:pushModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
    -- Grabbing2.ontoList = {}



    -- for key, value in pairs(gizmo.modeParents) do
    --     if type(key)=="string" or type(key)=="number" then
    --         Grabbing2.ontoList[#Grabbing2.ontoList+1] = key
    --         if key == gizmo.modeStack[#gizmo.modeStack-1] then
    --             Grabbing2.ontoIndex = #Grabbing2.ontoList
    --         end
            
    --     end
    -- end
    -- log(gizmo.modeStack[#gizmo.modeStack-1])
    host:swingArm(true)
    Grabbing.updateGUI()

end

--- note: this will continuously add onto the stack
function Grabbing.release(onto,center)
    if Grabbing.isGrabbing() then
        if onto == "ONTO" or true then
            onto = Grabbing.ontoList[Grabbing.ontoIndex]
        end
        if onto then
            AnchorAffix.complex.affixInPlace(Grabbing.carriedPartID,onto,center and onto or nil)

            -- Grabbing2.carriedObject:swapModeKeepPosParent(nex,("CarryingPart") --[[@as ID<ModelPart>]],true)
        else
            -- Grabbing2.carriedObject:popModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
        end
        Grabbing.carriedPartID = nil
        host:swingArm(true)
        -- Grabbing2.ontoList = {}
        Grabbing.updateGUI()
        return true
    end
end



function Grabbing.updateGUI()
    local text = Grabbing.GUI:getTask("text")
    text:setBackground(true):setBackgroundColor(vec(0x20,0x20,0x10,0x80)/0xFF)
    -- local selected = Grabbing.ontoList[Grabbing.ontoIndex] or "#¤#notpresent"
    -- local start = " | "
    -- local ende = " / "
    ---@type any[]
    local lines = {""}
    
    local rcPartID = (Grabbing.Selectable[(Grabbing.rc or {}).objectKey] or {}).partID 
    local ontoID = Grabbing.ontoList[Grabbing.ontoIndex]

    for index, listPartId in ipairs(Grabbing.ontoList) do
        
        local isAncestor = AnchorAffix.info.isChildOf(rcPartID,listPartId)
        local isOntoIndexAncestor = AnchorAffix.info.isChildOf(ontoID,listPartId)
        lines[#lines+1] = {
            text = listPartId .. "\n",
            color = (
                (Grabbing.isGrabbing() and index == Grabbing.ontoIndex)
                    and "#AA0011" 
                or (listPartId == (Grabbing.carriedPartID or {}) 
                    and "#0080FF" 
                or (listPartId) == rcPartID
                    and "#8080FF" 
                or (isAncestor)
                    and "#803030"
                or index == Grabbing.ontoIndex
                    and "#209030"
                or isOntoIndexAncestor
                    and "#206030"
                or "#FFFFFF")
            )
        }
    end
    if Grabbing.rc then
        -- lines[#lines+1] = {
        --     text = Utils.vectorString(Grabbing.rc.localPos),
        --     color = "#00FFFF"
        -- }
        local gizmo = Grabbing.hitboxToGizmo[Grabbing.rc.hitbox]
        lines[#lines+1] = {
            text = printTable(gizmo,1,true) .. "\n",
            color = "#AAAACA"
        }
        lines[#lines+1] = {
            text = printTable(Grabbing.rc,1,true) .. "\n",
            color = "#AACACA"
        }
        -- lines[#lines+1] = {
        --     text = printTable(Utils.getID(gizmo),1,true) .. "\n",
        --     color = "#ACAACA"
        -- }

        
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
    return Hitbox.raycastsOriented(eyePos,eyePos+100*dir,objects)

end

function grabKey.press()
    if not player:isLoaded() then return end
        
    local rc2 = raycastLook(Grabbing.Selectable)
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

function airKey.press()
    return Grabbing.grab(Grabbing.ontoList[Grabbing.ontoIndex])
end

function placeKey.press()
    return Grabbing.release("ONTO",true)
end

function events.mouse_scroll(dir)
    repeat
        Grabbing.ontoIndex = (Grabbing.ontoIndex - dir - 1) % (math.max(#Grabbing.ontoList,1)) + 1
    until not AnchorAffix.info.isChildOf(Grabbing.ontoList[Grabbing.ontoIndex],Grabbing.carriedPartID)
    Grabbing.updateGUI()
    if Grabbing.isGrabbing() then
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
local freecamKey = keybinds:newKeybind("move freecam's parent", "key.keyboard.e", false)

function freecamKey.press()
    
end

function freecamKey.release()
    
    AnchorAffix.complex.affixInPlace(AnchorAffix.info.getParentID("Freecam"))
    Utils.fromID("Freecam")
end



events.ENTITY_INIT:register(function ()
    
    for key, value in pairs(Utils.listIDd()) do
        if type(value.part) == "ModelPart" then
            Utils.setID(value.part,key.."_part")
        end
    end
    Utils.setID(
        Utils.fromID("TestObject_part"):newPart("freecam"),
        "Freecam"
    ):setPostRender(
      function (delta,ctx,part)
        if GIZMO.cameraTracking then
          local pos = part:partToWorldMatrix():apply( vec(0,0,0))
          renderer:setCameraPivot(nilInAerospace(pos + (vec(0,1,0) * ( - 0.2))))
        end
        if freecamKey:isPressed() then
            local pare = AnchorAffix.info.getParentID("Freecam")
            local change = player:getLookDir()*0.2
            AnchorAffix.complex.affixInPlace(pare,nil,Conversion.toMatrix(pare):translate(change),true)
        end

      end
    )
    -- Utils.setID(TestObject.part,"TestObject_part")
    -- Utils.setID()
    Grabbing.updateOntoList()
    for index, value in ipairs(Grabbing.ontoList) do
        Grabbing.addSelectable({partID = value, hitbox = Hitbox.fromModelPartItems(value)})
        
    end

end)







function Grabbing.allPlayers()
    for key, value in pairs((world.getPlayers()) ) do
        Utils.fromID("!pl:" .. key)
    end
end