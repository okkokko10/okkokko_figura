
require "floatingTool"
require "positioning"
require "playerValues"


-- require "grabFloatingGizmos"


Objects = {}
-- Objects.PlayerFollow = Positioning.entityFollower(PlayerValues,"PlayerFollow", false)

-- Objects.PlayerFollow = models:newPart("PlayerFollow","World")
--     :setPreRender(
--       function(delta, ctx, part)
--         if not player:isLoaded() then return end
--         part:setPos(PS*(PlayerValues.getPos(delta)))
--       end
--     )
-- Objects.World = models:newPart("World","World")


-- TestObject = FloatingObject:create(models:newPart("TestObject","LEFT_ITEM_PIVOT"),
--     {
--         base = Positioning.parts.PlayerFollower:newPart("TestObjectP1"):setPos(PS*1,PS/2,PS*3),
--     }):pushMode("base"):setID("TestObject")

local TestObject = Positioning.parts.MyBase:newPart("TestObject"):setPos(PS*1,PS/2,PS*3)
Utils.ID.field.TestObject = TestObject
TestObject:newItem("Item"):setItem("minecraft:glass"):setScale(0.5)
-- TestObject.part:addChild(vanilla_model.PLAYER)
local TestCompass = Positioning.make.absoluteRot("wa",TestObject)
TestCompass:newItem("Item"):setItem("minecraft:green_stained_glass")--:setScale(1/16)
-- local eye_text
local Eyes = Positioning.make.entityFollower(
{
    isLoaded = function (self)
        return player:isLoaded()
    end,
    getPos = function (self,delta)
        return vec(0,0,0)
    end,
    getRot = function (self,delta)
        if GIZMO.cameraTracking then
            eye_text:setOpacity(1):setSeeThrough(true)
            return  player:getRot(delta)
        else
            eye_text:setOpacity(0.5):setSeeThrough(false)

        end
    end

    },"FreecamEyes",2):moveTo(TestCompass)
local Eyes2 = Eyes:newPart("inner"):setRot(0,180,0)

eye_text = Eyes2:newText("face"):setText("O_O"):setAlignment("CENTER"):setSeeThrough(true):setPos(0,4.5,0)
local eye_block = Eyes:newItem("block"):setItem("blue_stained_glass_pane"):setScale(0.75)


function pings.setEyes(text,color,rotate)
    local t = toJson{
      text = text,
      color = color or "blue"
    }
    eye_text:setText(t):setRot(0,0,((rotate == true) and -90 or rotate) or 0)
    log("changed face to",t)
end

-- local text = TestObject.part:newText("text"):setSeeThrough(true)

-- TestObject:addHitbox(vec(0,0,0),1)
require("redo.Grab").addSelectableGenerate("TestObject")


-- Grabbing.addSelectable(TestObject)

do return end

-- local PointerObjectP1 = models:newPart("PointerObjectP1","World")

-- PointerObject = FloatingObject:create(models:newPart("PointerObject"),
--     {
--         base = PointerObjectP1,
--     }):pushMode("base")

-- PointerObject.part:newItem("Item2"):setItem("minecraft:orange_stained_glass"):setScale(1/8)


-- local function raycastSelectionCandidates(delta)
    
--     local eyePos = entityEyePos(player,delta or client.getFrameTime())
--     local dir = player:getLookDir()
--     local rc = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,Objects.SelectionCandidates)
--     return rc
-- end



-- PointerObjectP1:setPreRender(
--     function(delta, ctx, part)
--         if not player:isLoaded() then return end
        
--         local rc = raycastSelectionCandidates(delta)
--         -- text:setText(pos and (pos.x .. " " .. pos.y .. " " .. pos.z) or ".")
--         if rc then
--             part:setPos(PS*rc.globalPos)
--         end
--     end
-- )


-- ---@type FloatingObject?
-- Objects.Selected = nil

-- Objects.SelectionCandidates = {TestObject}

-- -- function events.tick()
-- --     local eyePos = entityEyePos(player)
-- --     local dir = player:getLookDir()
-- --     local obj, key, pos, side = FloatingObject.raycast(eyePos,eyePos+100*dir,{TestObject})
-- --     text:setText(pos and (pos.x .. " " .. pos.y .. " " .. pos.z) or ".")
-- --     if pos then
-- --         PointerObjectP1:setPos(PS*pos)
-- --     end
-- -- end




-- local toolPage = action_wheel:newPage("toolPage")
-- action_wheel:setPage(toolPage)



-- toolPage:newAction()
--     :title("look as gizmo")
--     :item("minecraft:blue_stained_glass_pane")
--     :hoverColor(0.9,0.4,0.9)
--     :onLeftClick(function()
--         if not Objects.Selected then return end
--         local w = client.generateUUID()
--         Objects.Selected:createParentInPlace(nil, w)
--         log(w)

--     end)
--     :onRightClick(function()
--         if Objects.Selected then
--             log(Objects.Selected:popMode())
--         end
--     end)
--     :onScroll(
--       function (dir)
    
--         if not player:isLoaded() then return end
--         if not Objects.Selected then return end
--         Objects.Selected:changePos(player:getLookDir()*dir)
--         -- local inv = sublevelRotationMatrixInv3(GIZMO.trackingOther)
--         -- local accountedDir = inv * player:getLookDir()
--         -- pings.setGizmo("trackingOther",GIZMO.trackingOther + accountedDir *dir * GIZMO.distance)
--       end

--     )

-- function pings.hideToolUse()
--     TestObject.part:setVisible(false)
--     TestCompass:setVisible(false)
-- end


-- toolPage:newAction()
--     :title("select")
--     :item("minecraft:stick")
--     :hoverColor(0.9,0.4,0.9)
--     :onLeftClick(function()
        
--     local rc = raycastSelectionCandidates()
--     -- logTable(rc)
--     if rc then
--         Objects.Selected = rc.obj
--     end
--     -- text:setText(pos and (pos.x .. " " .. pos.y .. " " .. pos.z) or ".")
--     -- if pos then
--     --     PointerObjectP1:setPos(PS*pos)
--     -- end

--     end)

-- toolPage:newAction()
--     :title("go to the previous")
--     :item("minecraft:grass_block")
--     :hoverColor(0.9,0.4,0.9)
--     :onLeftClick(function()
--         action_wheel:setPage(action_wheel:getPage("mainPage"))
--         pings.hideToolUse()
--     end)