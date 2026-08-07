
require"floatingTool"
require"positioning"
require"utils"
require"kineticsPath"

require"floatingToolUse"


-- Tablet = {}


Tablet = FloatingObject:create(models:newPart("Tablet"),
    {
        base = Positioning.parts.PlayerFollower:newPart("TestObjectP1"):setPos(PS*0,PS*1.5,PS*2),
    })

Tablet:addHitbox(vec(0,0,0),1)



Objects.SelectionCandidates[#Objects.SelectionCandidates+1] = Tablet

Tablet.part:newItem("back"):setItem("minecraft:cyan_stained_glass"):setScale(1,1,1/8)

local tabletButtons = {}

local watchedButton = nil

for i = 1, 4 do
    local tabletButton = FloatingObject:create(Tablet.part:newPart("button"), {
        base = Tablet.part:newPart(i):setPos(7,10-i*4,-2):setScale(1/8)
    })
    local ite = tabletButton.part:newItem("item"):setItem("minecraft:red_stained_glass")
    tabletButton.part:newText("text"):setText(i .. "......"):setPos(-16,0,8):setSeeThrough(true)
    tabletButton:addHitbox(vec(0,0,0),1/8)
    tabletButtons[i] = tabletButton
    tabletButton.part:setPreRender(
    function(delta, ctx, part) 
        ite:setItem(watchedButton == tabletButton and "minecraft:red_stained_glass" or "minecraft:white_stained_glass")
    end 
    
    )
end

local pressKey = keybinds:newKeybind("press", "key.mouse.right", false)

function pressKey.press()
    if not player:isLoaded() then return end
        
        local eyePos = entityEyePos(player,delta)
        local dir = player:getLookDir()
        local obj, key, pos, side = FloatingObject.raycast(eyePos,eyePos+100*dir,tabletButtons)
        if obj 
            
        then
            
    end
end

Tablet.part:setMidRender(
    function(delta, ctx, part)
        if not player:isLoaded() then return end
        
        local eyePos = entityEyePos(player,delta)
        local dir = player:getLookDir()
        local obj, key, pos, side = FloatingObject.raycast(eyePos,eyePos+100*dir,tabletButtons)
        watchedButton = obj
        
        if obj then
        end
    end
)

