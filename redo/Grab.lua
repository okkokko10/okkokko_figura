
require"positioning"
require"utils"
local AnchorAffix = require"./AnchorAffix"
local Hitbox = require"./Hitbox"


-- do return end


Utils.ID.field.CarryingPart = Positioning.parts.PlayerFollowerEyes:newPart("CarryingPart"):setPos(PS*vec(0,0,2))


--- todo: separate "grabbable" and "grabbing" logic.
--- make multiple grabbers possible.


Grabbing = {}

---@type ID<ModelPart>?
Grabbing.carriedPartID = nil

---@type HasPartIDHitbox[]
Grabbing.Selectable = {}
Grabbing.isSelectable = {}

-- function Grabbing.addSelectable(gizmo) end

Grabbing.GUI = models:newPart("GrabbingGUI2","GUI"):setPos(-client.getScaledWindowSize().xy_*vec(0.7,0.3,1))

Grabbing.GUI:newText("text"):setAlignment("LEFT") --:setScale(1/2)

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
    if not Utils.ID.from(gizmo.partID,"ModelPart") then
        error("adding ID-less object as grabbable: "..printTable(gizmo,1,true)) -- the error would have already happened
    end
    Grabbing.Selectable[#Grabbing.Selectable+1] = gizmo
    Grabbing.isSelectable[gizmo.partID] = #Grabbing.Selectable
    Grabbing.hitboxToGizmo[gizmo.hitbox] = gizmo
    -- for key, value in pairs(Positioning.parts) do -- I wonder, the order in which pairs runs is undefined behaviour, so it could lead to desync
    --     gizmo:createParent(value,key)
    -- end
end

--- todo: change this to GrabAttributes.<partID>.hitbox = <hitbox>

---@param partID ID<ModelPart>
function Grabbing.addSelectableGenerate(partID)
    Grabbing.addSelectable({partID = partID, hitbox = Hitbox.fromModelPartItems(partID)})
end


-- todo: place snapped to grid

-- todo: when grabbing an object, the action wheel is replaced
-- todo: when looking at an object, its parent is highlighted.

---@generic T
---@class Tree<T>
---@field [T] Tree<T>

---comment
---@param list ID<ModelPart>[]
---@return Tree<ID<ModelPart>>
---@return {[ ID<ModelPart> ] : Tree<ID<ModelPart>>} children
---@return ID<ModelPart>[] listed
---@return {[ ID<ModelPart> ] : number } listedInv
---@return {[ ID<ModelPart> ] : number } depth
function Grabbing.makeTree(list)
    local out = {}
    local tables = {}
    for index, value in ipairs(list) do
        tables[value] = {}
    end
    for key, value in pairs(tables) do
        local parent = AnchorAffix.info.getParentID(key)
        if key == Grabbing.carriedPartID then
            parent = Grabbing.oldParentID
        end
        if parent then
            if tables[parent] then
                tables[parent][key]=value
            else
                log("strange grabbing:",parent,key,value)
                out[key] = value
            end
        else
            out[key] = value
        end
    end
    local listed = {}
    local listedInv = {}
    local depth = {}
    local function f(tbl,d)
        for key, value in pairs(tbl) do
            depth[key] = d
            listed[#listed+1] = key
            listedInv[key] = #listed
            f(value,d+1)
        end
    end
    f(out,0)
    return out,tables,listed,listedInv,depth
end

function Grabbing.canGrab(partID)
    return Grabbing.isSelectable[partID]
end
function Grabbing.canAffixTo(partID)
    return true -- todo
end


Grabbing.ontoTree = {}
Grabbing.ontoDepth = {}

---sets ontoList as the list of IDd ModelParts
function Grabbing.updateOntoList()
    local initial = {}
    for id, value in pairs(Utils.ID.listIDd()) do
        if type(value) == "ModelPart" and id ~= "CarryingPart" then
            initial[#initial+1] = id
        end
    end
    Grabbing.ontoTree,_,Grabbing.ontoList,Grabbing.ontoListInv,Grabbing.ontoDepth = Grabbing.makeTree(initial)
end

function Grabbing.isGrabbing()
    return not not Grabbing.carriedPartID
end

---comment
---@param partID ID<ModelPart>
function Grabbing.grab(partID)
    if Grabbing.isGrabbing() or not Utils.ID.isID(partID) or (not Grabbing.canGrab(partID)) then return end
    Grabbing.carriedPartID = partID
    local parentID = AnchorAffix.info.getParentID(partID)
    Grabbing.oldParentID = parentID
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


function Grabbing.release(onto,center)
    if Grabbing.isGrabbing() then
        if not onto then
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
        --Grabbing.updateOntoList() -- this errors because of ping async behaviour
        Grabbing.updateGUI()
        return true
    end
end

--- animation idea: pistons emerge from portals?
--- a piston at the end of an arm emerges from the ground below


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
        
        local depth = Grabbing.ontoDepth[listPartId] or 0

        local isAncestor = false and AnchorAffix.info.isChildOf(rcPartID,listPartId)
        local isOntoIndexAncestor = false and AnchorAffix.info.isChildOf(ontoID,listPartId)
        local isManaged = Positioning.isManaged(listPartId)

        local isSelectable = Grabbing.isSelectable[listPartId]
        local right = (isSelectable and " +" or "") .. (isManaged and (Positioning.isActive(listPartId) and " ---" or " - -") or "")
        local left = string.rep("   ",depth)

        lines[#lines+1] = {
            text = left .. listPartId .. right ..  "\n",
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
    if Grabbing.rc and false then
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
        --     text = printTable(Utils.ID.getID(gizmo),1,true) .. "\n",
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



function Grabbing.raycastLook(objects,delta)
    if not player:isLoaded() then return end
    local eyePos = Utils.entity.entityEyePos(player,delta or client.getFrameTime())
    local dir = player:getLookDir()
    return Hitbox.raycastsOriented(eyePos,eyePos+100*dir,objects)

end



if host:isHost() then
    events.TICK:register(function ()
        
        if not player:isLoaded() then return end
            
        local rc2 = Grabbing.raycastLook(Grabbing.Selectable)
        Grabbing.rc = rc2
        Grabbing.updateOntoList()
        Grabbing.updateGUI()
    end)
    events.ENTITY_INIT:register(function ()

        Grabbing.updateOntoList()
    end)
end









function Grabbing.allPlayers()
    for key, value in pairs((world.getPlayers()) ) do
        Utils.ID.from("!pl:" .. key)
    end
    Grabbing.updateOntoList()
end



return Grabbing