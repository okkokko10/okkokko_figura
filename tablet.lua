
require"floatingTool"
require"positioning"
require"utils"
require"kineticsPath"

require"floatingToolUse"
require "grabFloatingGizmos"


-- -- Tablet = {}

-- Tablet = FloatingObject:create(models:newPart("Tablet"),
--     {
--         base = Positioning.parts.PlayerFollower:newPart("TabletP"):setPos(PS*0,PS*1.5,PS*2),
--     })

-- Tablet:setID("Tablet")

-- Tablet:addHitbox(vec(0,0,0),vec(1,1,1/8))


-- Grabbing.addSelectable(Tablet)


-- Tablet.part:newItem("back"):setItem("minecraft:cyan_stained_glass"):setScale(1,1,1/8)

-- local tabletButtons = {}

-- local watchedButton = nil

-- for i = 1, 4 do
--     local tabletButton = FloatingObject:create(Tablet.part:newPart("button"), {
--         base = Tablet.part:newPart(i):setPos(7,10-i*4,-2):setScale(1/8)
--     })
--     local ite = tabletButton.part:newItem("item"):setItem("minecraft:red_stained_glass")
--     tabletButton.part:newText("text"):setText(i .. "......"):setPos(-16,0,8):setSeeThrough(true)
--     tabletButton:addHitbox(vec(0,0,0),1)
--     tabletButtons[i] = tabletButton
--     tabletButton.part:setPreRender(
--     function(delta, ctx, part)
--         ite:setItem(watchedButton == tabletButton and "minecraft:red_stained_glass" or "minecraft:white_stained_glass")
--     end 
    
--     )
-- end



-- Tablet.part:setPostRender(
--     function(delta, ctx, part)
--         if not player:isLoaded() then return end
        
--         local eyePos = entityEyePos(player,delta)
--         local dir = player:getLookDir()
--         local obj = FloatingObject.raycastsOriented(eyePos,eyePos+100*dir,tabletButtons)
--         watchedButton = obj and obj.obj
        
--         if obj then
--         end
--     end
-- )



---@generic T : { setPos:fun(), setScale:fun()}
---@param target T
---@param pos1 Vector
---@param pos2 Vector
---@param posScaling? number -- 
---@param scaleScaling? number -- 
---@return T
function Utils.math.setPosScaleFromEndpoints(target,pos1,pos2,posScaling,scaleScaling)
    local a, b = Utils.math.edgesToPosScale(pos1,pos2)
    return target:setPos((posScaling or PS)*a):setScale((scaleScaling or 1) * b)
end


---@class Tablet
---@field part ModelPart
---@field buttonRules ButtonRule[]
---@field buttonObjects FloatingObject[]
---@field hoveredButton number?
---@field extraData? table
---@field minpos Vector
---@field maxpos Vector
Tablet = {}
Tablet.__index = Tablet

---todo: knob (when held, reacts to scrolling), lever, 2d lever
---      
--- todo: tablets cannot be grabbed by the buttons.
--- 
--- todo: associate FloatingObject and Tablet parts back to the owner, limited to 1? or maybe not, that might limit copying
--- FloatingObject and Tablet should share a superclass WithPart, that also inherits from IdUtils (and make IdUtils keys separate?)
--- ButtonRule also takes WithPart

--- buttons should have an onEnterHover, onExitHover

--- 
---@alias ButtonPress fun(key:string,tablet:Tablet,buttonIndex:number)

---@class ButtonRule
---@field type? string
---@field onPress? ButtonPress
---@field onRelease? ButtonPress
---@field part? ModelPart
---@field data? any
---@field text? string
-- ButtonRule = {}
-- ButtonRule.__index = ButtonRule

---comment
---@param name string
---@param buttonRules ButtonRule[]
function Tablet.newTablet(name,buttonRules)
    ---@type Tablet
    local tablet = setmetatable({},Tablet)

    local rules = {
        spacing = 1/4,
        scale = 1/8,
        hpad = 1/8,
        vpad = 1/8
    }

    local length = rules.spacing * (#buttonRules-1) + rules.scale + rules.vpad*2
    

    tablet.minpos = vec(0,0,0)
    tablet.maxpos = vec(-1,-length,1/8)


    tablet.part = models:newPart(name)
    Utils.math.setPosScaleFromEndpoints(
        tablet.part:newItem("back"):setItem("minecraft:purple_stained_glass"),
        tablet.minpos,tablet.maxpos
    )
    -- tablet.part:newBlock("back2"):setBlock("minecraft:green_stained_glass")--:setPos(PS*vec(1,1,1)/2):setScale(1,1,1)
    tablet.buttonRules = buttonRules
    tablet.buttonObjects = {}
    


    for i, value in ipairs(buttonRules) do
        local pos = vec(0,(1-i)*rules.spacing-rules.vpad,-0.001)
        --- should use a superclass instead
        local tabletButton = FloatingObject:create(tablet.part:newPart("button"), {
            base = Utils.math.setPosScaleFromEndpoints(
                tablet.part:newPart(i),
                pos,
                pos - rules.scale
                )
        })
        tablet.buttonObjects[i] = tabletButton
        local ite = tabletButton.part:newItem("item"):setItem("minecraft:red_stained_glass")
        tabletButton.part:newText("text"):setText(value.text):setPos(-16,0,8):setSeeThrough(true)
        tabletButton:addHitbox(vec(0,0,0),1)
        tabletButton.part:setPreRender(
        function(delta, ctx, part)
            ite:setItem(tablet.buttonObjects[tablet.hoveredButton] == tabletButton and "minecraft:red_stained_glass" or "minecraft:white_stained_glass")
        end 
        
        )
    end
    
    tablet.part:setPostRender(
        function(delta, ctx, part)
            if not player:isLoaded() then return end
            local eyePos = entityEyePos(player,delta)
            local dir = player:getLookDir()
            local obj = tablet:Hover(eyePos,eyePos+100*dir)
        end
    )


    return tablet
end

function Tablet:Hover(startPos,endPos)
    local rc = FloatingObject.raycastsOriented(startPos,endPos,self.buttonObjects)
    if rc then
        self.hoveredButton = rc.objectKey
    else
        self.hoveredButton = nil
    end
end




--- idea: there is a "room" that is a floating part and also an anchor

--- todo: when a FloatingObject is fixed to a ID registered anchor point for the first time, that's when it gets a modeParent, unless it already has one.
--- that modeParent is then named the same
--- in non-host, the anchor point could be the one that moves, since the matrix is communicated anyway


local tablet2 = Tablet.newTablet("tablet2",{
    {},{},{}
})
local Tablet2 = FloatingObject:create(tablet2.part,
    {
        base = Positioning.parts.PlayerFollowerYaw:newPart("Tablet2P"):setPos(PS*(0.1),PS*1.5,PS*2),
    })







Tablet2:setID("Tablet2")

Tablet2:addHitboxEdges(tablet2.minpos,tablet2.maxpos)


Grabbing.addSelectable(Tablet2)


