
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

function Testing.active2()


    local atlas = {
        name1 = models:newPart("model"):remove()
    }
    atlas.name1:newItem("item"):item("minecraft:glass"):setPos(-8):setScale(1/2)
    InsertText.render(Testing.part,InsertText.test_text2,atlas)
    

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



 
return Testing

