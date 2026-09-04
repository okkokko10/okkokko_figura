
--[[
create:redstone_link[facing=up,
powered=false,
receiver=true]{ FrequencyFirst:{ count:1,
id:"analogaudio:radio"},
FrequencyLast:{ components:{ "analogaudio:frequency":4},
count:1,
id:"analogaudio:walkie_talkie"},
LastKnownPosition:-8521214844865L,
LinkedGauges:[],
Receive:0,
ReceivedChanged:0b,
Transmit:0,
Transmitter:0b}


create:redstone_link[facing=up,
powered=false,
receiver=false]{ FrequencyFirst:{ components:{ "minecraft:damage":7,
"minecraft:enchantments":{ levels:{ "minecraft:mending":1,
"minecraft:unbreaking":3}},
"minecraft:repair_cost":3},
count:1,
id:"create:extendo_grip"},
FrequencyLast:{ components:{ "minecraft:custom_name":'"Long Fall Boots"',
"minecraft:damage":18,
"minecraft:enchantments":{ levels:{ "minecraft:depth_strider":3,
"minecraft:feather_falling":4,
"minecraft:mending":1,
"minecraft:protection":4,
"minecraft:unbreaking":3}},
"minecraft:repair_cost":3,
"minecraft:trim":{ material:"minecraft:redstone",
pattern:"minecraft:bolt"}},
count:1,
id:"minecraft:netherite_boots"},
LastKnownPosition:-10170482311101L,
LinkedGauges:[],
Receive:0,
ReceivedChanged:0b,
Transmit:0,
Transmitter:1b}

]]

--- todo: similarly to grabbing, scroll through to see the overlays




local RedstoneLinks = {}


---@class FrequencyItem
---@field id string
---@field tag { ["minecraft:dyed_color"] : {rgb:number}?, ["minecraft:custom_name"] : string? }


-- -@field color? number
-- -@field name? string


---@alias Strength integer

---@class RedstoneLink
---@field Receive Strength
---@field ReceivedChanged Strength
---@field Transmit Strength
---@field Transmitter boolean
---@field paths {[RedstoneLink]: ModelPart}
---@field pos Vector

---@class Frequency
Frequency = {}
Frequency.__index = Frequency

Frequency.stored = {}
Frequency.stored_index = {}


function Frequency.itemFromEntry(frequencyN)
    local components = (frequencyN.components or {})
    local dyed_color = components["minecraft:dyed_color"]
    local custom_name = components["minecraft:custom_name"]
    return world.newItem(frequencyN.id .. "[" .. 
        (dyed_color and ("minecraft:dyed_color=" .. (toJson(dyed_color)) .. ",") or "") ..
        (custom_name and ("minecraft:custom_name=" .. (toJson(custom_name)) .. ",") or "") .. "]")


   -- return {id = frequencyN.id, color = ((frequencyN.components or {})["minecraft:dyed_color"] or {}).rgb, name = (f1.components or {})["minecraft:custom_name"]}
end

---comment
---@param block BlockState
---@return Frequency?
function Frequency.fromBlock(block)
    if not (block.id == "create:redstone_link") then return end
    local data = block:getEntityData()
    if not data then
        log("no data in link:")
        logTable(block)
    end


    local f1 = data.FrequencyFirst
    local f2 = data.FrequencyLast
    if not (f1 and f2) then return end
    return Frequency.fromItems(Frequency.itemFromEntry(f1),Frequency.itemFromEntry(f2))
    -- local o1 = {id = f1.id, color = ((f1.components or {})["minecraft:dyed_color"] or {}).rgb, name = (f1.components or {})["minecraft:custom_name"]}
    -- local o2 = {id = f2.id, color = ((f2.components or {})["minecraft:dyed_color"] or {}).rgb, name = (f2.components or {})["minecraft:custom_name"]}
end

function Frequency.makeStr(FrequencyFirst,FrequencyLast)
    return RedstoneLinks.frequencyFromItem(FrequencyFirst) .. "|" .. RedstoneLinks.frequencyFromItem(FrequencyLast)
end

---comment
---@param FrequencyFirst any
---@param FrequencyLast any
---@return Frequency
function Frequency.fromItems(FrequencyFirst,FrequencyLast)
    local str = Frequency.makeStr(FrequencyFirst,FrequencyLast)
    if Frequency.stored[str] then
        return Frequency.stored[str]
    end
    ---@class Frequency
    local out = setmetatable({str = str, FrequencyFirst = FrequencyFirst, FrequencyLast = FrequencyLast},Frequency)
    Frequency.stored[str] = out
    Frequency.stored_index[#Frequency.stored_index+1] = str
    out.index = #Frequency.stored_index

    ---vectors can be used as keys
    ---@type {[Vector] : RedstoneLink}
    out.positions = {}
    out:init()
    return out
end

Frequency.uiRootPart = models:newPart("FrequenciesUI","GUI"):setPos(-client.getScaledWindowSize().xy_*vec(0.3,0.3,1))
Frequency.uiRootPart:setPos(-client.getScaledWindowSize().xy_*vec(0.3,0.5,1))
Frequency.pathsRootPart = models:newPart("FrequenciesPaths","World")


--- /figura run itemtest = Grabbing.GUI:newItem("item"):setItem(world.newItem(player:getHeldItem():toStackString()))
--- /figura run freq1 = KineticsPath.getFirstBlock():getEntityData().FrequencyFirst
--- /figura run Itemtest(player:getHeldItem():toStackString():gsub(" ", "_"))
--- /figura run Itemtest("minecraft:leather_horse_armor[minecraft:dyed_color={rgb:100},minecraft:custom_name=\"Global_Data\"]")
--- 
local itemtest = Grabbing.GUI:newItem("item")
function Itemtest(str)
    local w = world.newItem(str)
    itemtest:setItem(w)
    return w
end

function Frequency:init()
    self.uiPart = Frequency.uiRootPart:newPart(self.str):setPos(0,32*self.index,0)
    self.firstItem = self.uiPart:newItem("first"):setItem(self.FrequencyFirst)
    self.lastItem = self.uiPart:newItem("last"):setItem(self.FrequencyLast):setPos(-32,0,0)
    self.text = self.uiPart:newText("text"):setText(self.str):setPos(-64,0,1):setAlignment("LEFT")
    self.pathsPart = Frequency.pathsRootPart:newPart(self.str)
end

function Frequency:update()
    
end





---comment
---@param from RedstoneLink
---@param to RedstoneLink
function Frequency:createPath(from,to)
    if to.Transmitter then
        if from.Transmitter then
            return
        else
            return self:createPath(to,from)
        end
    else
        if not from.Transmitter then return end
    end
    if (not from.Transmitter) or to.Transmitter then return end    
    if from.paths[to] then return end
    
    from.paths[to] = DrawLine.line(self.pathsPart:newPart(tostring(from.pos).."<>"..tostring(to.pos)),from.pos*PS,to.pos*PS)

    


    
end


---it should already be checked that this
---@param block BlockState
function Frequency.introduceBlock(block)
    local pos = block:getPos()
    local freq = Frequency.fromBlock(block)
    if not freq then
        --- todo: if there used to be a link here, remove it?
        return
    end
    local rl = freq.positions[pos] or {}
    local data = block:getEntityData()

    rl.Receive = data.Receive
    rl.ReceivedChanged = data.ReceivedChanged
    rl.Transmit = data.Transmit
    rl.Transmitter = data.Transmitter == 1
    

    if not freq.positions[pos] then
        rl.pos = pos
        rl.paths = {}
        for key, value in pairs(freq.positions) do
            freq:createPath(rl,value)
        end

        freq.positions[pos] = rl
    end
    
end


function Frequency:updateStrength(strength)
    self.strength = strength
    self.text:setText(tostring(self.strength))
end


function Utils.math.vectorMin(a,b)
    return a:copy():applyFunc(function (x,i)
        return math.min(x,b[i])
    end)
end
function Utils.math.vectorMax(a,b)
    return a:copy():applyFunc(function (x,i)
        return math.max(x,b[i])
    end)
end

Utils.Scan = {}

Utils.Scan.queued_scans = {}
Utils.Scan.queued_scans_index = 1



function Utils.Scan.order_scan1(pos1,pos2,func,onFinish)
    Utils.Scan.queued_scans[#Utils.Scan.queued_scans+1] = {pos1=pos1,pos2=pos2,func=func,onFinish=onFinish}
end

events.TICK:register(function ()
    if #Utils.Scan.queued_scans > Utils.Scan.queued_scans_index then
        local sc = Utils.Scan.queued_scans[Utils.Scan.queued_scans_index]
        Utils.Scan.queued_scans_index = Utils.Scan.queued_scans_index + 1
        local blocks = world.getBlocks(sc.pos1,sc.pos2)
        
    end
end)



---comment
---@param rect Rect
---@param func fun(block:BlockState)
function Utils.Scan.foreach(rect,func)
    if not rect then return end
    local pos1 = rect.min
    local pos2 = rect.max
    local size = rect.size
    for x = 0, size.x, 8 do
        for y = 0, size.y,8 do
            for z = 0, size.z,8 do
                local lpos = pos1+vec(x,y,z)
                local lsize = vec(8,8,8)
                local tbl = world.getBlocks(lpos,Utils.math.vectorMin(pos2,lpos+lsize))
                for key, value in pairs(tbl) do
                    func(value)
                end
            end
        end
    end
end


function Frequency.scanArea1(pos)
    pos = pos or select(2, (host:isHost() and host or Utils.Nop):getPickBlock()) or client.getCameraPos()
    local min = pos - vec(4, 4, 4)
    local max = pos + vec(4, 4, 4)
    local blocks = world.getBlocks(min, max)
    return blocks
end

function Frequency.scanArea(pos)
    pos = pos or select(2, (host:isHost() and host or Utils.Nop):getPickBlock()) or client.getCameraPos()
    -- local min = pos - vec(4, 4, 4)
    -- local max = pos + vec(4, 4, 4)
    Utils.Scan.foreach(Rect.fromPosSize(pos,vec(16,16,16)),Frequency.introduceBlock)
    -- for key, value in pairs(blocks) do
    --     Frequency.introduceBlock(value)
    -- end
end


---@param item ItemStack
---@return string
function RedstoneLinks.frequencyFromItem(item)
    if not item then return "" end
    local color = item.tag["minecraft:dyed_color"]
    if color then
        color = color.rgb
    end
    return item.id .. (color and ("#" .. string.format("%X",tonumber(color))) or "")
end


RedstoneLinks.storedPositions = {}

---comment
---@param block BlockState
function RedstoneLinks.introduceBlock(block)
    if not block.id == "create:redstone_link" then return end
end





---comment
---@param strength Strength
---@param frequencyFirst ItemStack
---@param frequencyLast ItemStack
function RedstoneLinks.updateReading(strength,frequencyFirst,frequencyLast)
    
end

