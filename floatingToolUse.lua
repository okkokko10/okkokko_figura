
require "floatingTool"
require "positioning"
require "playerValues"



Objects = {}
Objects.PlayerFollow = Positioning.entityFollower(PlayerValues,"PlayerFollow", 2)

-- Objects.PlayerFollow = models:newPart("PlayerFollow","World")
--     :setPreRender(
--       function(delta, ctx, part)
--         if not player:isLoaded() then return end
--         part:setPos(PS*(PlayerValues.getPos(delta)))
--       end
--     )
Objects.World = models:newPart("World","World")


TestObject = FloatingObject:create(models:newPart("TestObject","LEFT_ITEM_PIVOT"),
    {
        base = Objects.PlayerFollow:newPart("TestObjectP1"):setPos(PS*2,PS/2,0),
    }):pushMode("base")

TestObject.part:newItem("Item"):setItem("minecraft:glass")
-- TestObject.part:addChild(vanilla_model.PLAYER)
TestCompass = Positioning.absoluteRot("wa",TestObject.part)
TestCompass:newItem("Item"):setItem("minecraft:green_stained_glass")--:setScale(1/16)