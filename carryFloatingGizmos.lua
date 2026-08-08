
require"floatingTool"
require"positioning"
require"utils"
require"kineticsPath"

require"floatingToolUse"


local pressKey = keybinds:newKeybind("press", "key.mouse.right", false)


local carryingPart = Utils.setID(Positioning.parts.PlayerFollowerEyes:newPart("CarryingPart"),"CarryingPart")
---@type FloatingObject
local carriedObject


function pressKey.press()
    if not player:isLoaded() then return end
        
    local eyePos = entityEyePos(player,delta)
    local dir = player:getLookDir()
    -- local rc = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,tabletButtons)
    -- if rc then
    --     -- rc.obj
    -- end

    local rc2 = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,Objects.SelectionCandidates)

    if rc2 then
        carriedObject = rc2.obj
        carriedObject:pushModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
        return true
    end
end

function pressKey.release()
    if carriedObject then
        carriedObject:popModeKeepPosParent(("CarryingPart") --[[@as ID<ModelPart>]],true)
    end
end

