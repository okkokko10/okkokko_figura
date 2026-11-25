
local START_WITH_TESTING_PART = true

require"redo.Grab"

Testing = {}



Testing.part = models:newPart("TestingPart"):remove()

Testing.part:newPart("reference"):newBlock("target"):setBlock("minecraft:target")

Utils.ID.field.TestingPart = Testing.part

Grabbing.addSelectableWithHitbox("TestingPart",Hitbox:create("TestingPart",Rect.unit*PS))

function Testing.PLAYER_CHUNK_CORNER_CEIL()
    local x,y,z = player:getPos():unpack()
    local ax = Utils.math.floor(x,16) + 16
    local ay = Utils.math.floor(y,16) + 16
    local az = Utils.math.floor(z,16) + 16
    return vec(ax,ay,az)
    
end
function Testing.SUMMON_TESTING_PART()
    -- local bl = player:getTargetedBlock()
    -- local pos = bl and bl:getPos() or player:getPos()
    -- pos = pos + vec(0,1,0)
    local pos = Testing.PLAYER_CHUNK_CORNER_CEIL()
    AnchorAffix.complex.affixInPlace("TestingPart","World",(pos:augmented(PS)),true)
end



function Testing.dumpChars(start,width)
    
    local chars = {}
    for i = start or 0, (width and (start + width)) or 255 do
        local x,y = client.getTextDimensions(string.char(i)):unpack()
        local w = client.getTextDimensions(string.char(i))
        chars[1+i] = string.char(0,i,0) .. (' %X: \t%i %s'):format(i,x, y == 9 and "" or ("height: " .. y))
    end
    local out = table.concat(chars,"\n")
    
    return out
    
end

function Testing.dumpCharsPart()
    
    local part = Testing.part:newPart("dumpChars")

    local side = string.char(0x3A)
    local side_width = client.getTextDimensions(side).x
    
    for i = 0, 255 do
        local grid_pos = vec(i%16,math.floor(i/16),0)
        local pos = -grid_pos*16
        local name = tostring(i)
        
        local ch = string.char(i)
        local x,y = client.getTextDimensions(ch):unpack()
        local compare = client.getTextDimensions(ch .. side).x - side_width
        
        
        
        local exp = string.char(0,i,0) .. (' %X: \t%i %s'):format(i,x, y == 9 and "" or ("height: " .. y))
        exp = ('%02X x:%i %s'):format(i,x, y == 9 and "" or ("y:" .. y))
        
        if compare ~= x then
            exp = exp .. (" adds: %i"):format(compare)
        end
        
        -- part:newBlock(name.."block"):block("minecraft:target"):setPos(pos - vec(16,16,-0.01))
        local color = vec((i%4)/4,0,1,0.5)
        
        part:newText(name):text(ch):pos(pos)
        :backgroundColor(color)
        
        part:newText(name.."side"):text(ch .. side):pos(pos + vec(0,0,16))
        :backgroundColor(color)
        
        
        part:newText(name.."exp"):text(exp):pos(pos - vec(0,10,0)):scale(1/8)
        
    end
end


function Testing.dumpCharsPartInit()
    
    local part = Testing.part:newPart("dumpChars")

    part:newText("info"):pos(0,16,0)
        :backgroundColor(0,1,1,1)
    part:newText("infoexp"):pos(vec(0,6,0)):scale(1/8)
    
    for i = 0, 255 do
        local grid_pos = vec(i%16,math.floor(i/16),0)
        local pos = -grid_pos*16
        local name = tostring(i)
        -- part:newBlock(name.."block"):block("minecraft:target"):setPos(pos - vec(16,16,-0.01))
        local color = vec((i%4)/4,0,1,0.5)
        
        part:newText(name):pos(pos)
        :backgroundColor(color)
        
        part:newText(name.."side"):pos(pos + vec(0,0,16))
        :backgroundColor(color)

        part:newText(name.."exp"):pos(pos - vec(0,10,0)):scale(1/8)
        
    end
end

function Testing.dumpCharsPartView(prev,post)
    
    local part = Testing.part.dumpChars
    if not part then return end
    if type(prev) == "number" then
        prev = string.char(prev)
    end
    local side = prev
    local side_width = client.getTextDimensions(side).x

    local info = part:getTask("info") --[[@as TextTask]]
    local infoexp = part:getTask("infoexp") --[[@as TextTask]]
    info:text(side)
    infoexp:text(side == "" and "none" or ("%02X"):format(string.byte(side)))
    
    for i = 0, 255 do
        local grid_pos = vec(i%16,math.floor(i/16))
        local pos = -grid_pos*16
        local name = tostring(i)
        local t_main = part:getTask(name) --[[@as TextTask]] 
        local t_side = part:getTask(name.."side")--[[@as TextTask]] 
        local t_exp  = part:getTask(name.."exp") --[[@as TextTask]] 
        
        local ch = string.char(i)
        local side_ch = side .. ch .. (post or "")
        -- side_ch = ('[{"text":%q, "font":"uniform"}]'):format(side_ch)
        local x,y = client.getTextDimensions(side_ch):unpack()
        -- local compare = client.getTextDimensions(side_ch).x - side_width
        
        
        
        local exp = string.char(0,i,0) .. (' %X: \t%i %s'):format(i,x, y == 9 and "" or ("height: " .. y))
        exp = ('%02X x:%i %s'):format(i,x, y == 9 and "" or ("y:" .. y))
        
        -- if compare ~= x then
        --     exp = exp .. (" adds: %i"):format(compare)
        -- end
        
        if x > 50 then
            t_main:text()
        else
            t_main:text(side_ch)
        end
        -- t_side:text(side_ch)
        t_exp:text(exp)
        
        
    end
    -- local out = table.concat(chars,"\n")
    
    -- return out
    
end


function Testing.active1()

    -- Testing.dumpCharsPartInit()
    -- local i = 0
    -- events.TICK:register(function ()
    --     i = i + 0.1
    --     Testing.dumpCharsPartView(math.floor(i))

    -- end)

    -- /figura run Iaw = 0xD0
    -- !#(function() Iaw = (Iaw or -1) + 1; return Iaw end) ()#!!#Testing.dumpCharsPartView(Iaw)#!
    
    -- !#Testing.dumpCharsPartView("\xFF\xFF\x28\xFF\xFF")#!

    

end

Testing.InsertText = {}


function Testing.active2()

    
    local atlas = {
        name1 = models:newPart("model"):remove()
    }
    atlas.name1:newItem("item"):item("minecraft:glass"):setPos(-8,-8,-8):setScale(1)
    
    Testing.InsertText.cells = {
        {"line 1", "  a", ". .", "<>", atlas.name1, {height = 16, width = 16}, " bc"},
        {"line  2", " b"},
        {"line   3", {head = {scale = 2}}, "c","d"},
        {"line 4", "d", atlas.name1},
    }
    Testing.InsertText.cells_hierarchy = InsertText.parseCells(Testing.InsertText.cells)

    Testing.InsertText.state = InsertText.render(Testing.part,Testing.InsertText.cells_hierarchy,atlas)
    -- InsertText.render(Testing.part,InsertText.test_text2,atlas)
    -- events.TICK:register(function ()
    --     InsertText.render(Testing.part,Testing.InsertText.cells_hierarchy,atlas)
        
    -- end)

    

end



---@param message? string
---@param json? string
---@return string|false? replace
---@return Vector3? bgcolor
function Testing.test_dimensions_chat_receive_message(message, json)
    local out = ('{"extra":[%s], "text":""}'):format(json)
    local message_dim = client.getTextDimensions(message)
    local json_dim = client.getTextDimensions(json)
    local out_dim = client.getTextDimensions(out)
    host:setClipboard(('%s  %s  %s'):format(tostring(message_dim), tostring(json_dim), tostring(out_dim)))
    return json
end

-- events.CHAT_RECEIVE_MESSAGE:register(Testing.test_dimensions_chat_receive_message)


function Testing.world_newItem()
    local item = player:getHeldItem()
    log(item)
    local stack_string = item:toStackString()
    log(stack_string)
    local new_item = world.newItem(stack_string)
    log(new_item)
end

Testing.item_enchantments = {}

function Testing.item_hover()
    
    -- local item = player:getHeldItem()
    -- log(item)
    -- local stack_string = item:toStackString()
    

    local first_item = player:getNbt().Inventory[1]
    -- logTable(first_item,3)

    printJson(toJson{
        text = "item",
        hoverEvent = {
            action = "show_item",
            contents = first_item
        }
    })
end

Testing.item_enchantments.simpler_unenchanted = '{"text":"unenchanted","hoverEvent":{"contents":{"id":"minecraft:netherite_sword","components":{"minecraft:enchantments":{"levels":{}}}},"action":"show_item"}}'
Testing.item_enchantments.unenchanted = ('{"text":"","extra":[%s]}'):format(Testing.item_enchantments.simpler_unenchanted)
Testing.item_enchantments.simpler_enchanted = '{"text":"enchanted","hoverEvent":{"contents":{"id":"minecraft:netherite_sword","components":{"minecraft:enchantments":{"levels":{"minecraft:mending":1}}}},"action":"show_item"}}'
Testing.item_enchantments.enchanted = ('{"text":"","extra":[%s]}'):format(Testing.item_enchantments.simpler_enchanted)


--- shows that printJson cannot do a hoverEvent with enchantments unlike tellraw
function Testing.item_enchantments.item_hoverText_tellraw()


    printJson(Testing.item_enchantments.unenchanted)
    printJson("\n\n")
    printJson( Testing.item_enchantments.enchanted)
    printJson("\n\n")
    printJson( Testing.item_enchantments.simpler_enchanted)
    printJson("\n\n")
    host:sendChatCommand("/tellraw @s " .. Testing.item_enchantments.simpler_enchanted)
end

function Testing.item_enchantments.item_hoverText_tellraw_only()

    local unenchanted = '{"text":"","extra":[{"text":"unenchanted","hoverEvent":{"contents":{"id":"minecraft:netherite_sword","components":{"minecraft:enchantments":{"levels":{}}}},"action":"show_item"}}]}'
    local enchanted = '{"text":"","extra":[{"text":"enchanted","hoverEvent":{"contents":{"id":"minecraft:netherite_sword","components":{"minecraft:enchantments":{"levels":{"minecraft:mending":1}}}},"action":"show_item"}}]}'

    host:sendChatCommand("/tellraw @s " .. unenchanted)
    host:sendChatCommand("/tellraw @s " .. enchanted)

end


function Testing.active()
    Testing.active2()
end


if host:isHost() then
    
if host:isHost() and START_WITH_TESTING_PART then
    events.ENTITY_INIT:register(function ()
        Testing.SUMMON_TESTING_PART()
        Testing.active()
    end)
end
end

-- !#(function(x) MYS = x; return x end)(host:getChatMessage(16)).#!

 
return Testing

