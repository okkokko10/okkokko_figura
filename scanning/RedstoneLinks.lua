
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
]]
local RedstoneLinks = {}



local Frequency = {}
Frequency.__index = Frequency

Frequency.stored = {}
Frequency.stored_index = {}

function Frequency.makeStr(FrequencyFirst,FrequencyLast)
    return RedstoneLinks.frequencyFromItem(FrequencyFirst) .. "|" .. RedstoneLinks.frequencyFromItem(FrequencyLast)
end

function Frequency.fromItems(FrequencyFirst,FrequencyLast)
    local str = Frequency.makeStr(FrequencyFirst,FrequencyLast)
    if Frequency.stored[str] then
        return Frequency.stored[str]
    end
    local out = setmetatable({str = str, FrequencyFirst = FrequencyFirst, FrequencyLast = FrequencyLast},Frequency)
    Frequency.stored[str] = out
    Frequency.stored_index[#Frequency.stored_index+1] = str
    out.index = #Frequency.stored_index
    out:init()
    return out
end

Frequency.rootPart = models:newPart("Frequencies","GUI")


function Frequency:init()
    self.part = Frequency.rootPart:newPart(self.str):setPos(100,32*self.index,0)
    self.firstItem = self.part:newItem("first"):setItem(self.FrequencyFirst)
    self.lastItem = self.part:newItem("last"):setItem(self.FrequencyLast):setPos(32,0,0)
    self.text = self.part:newText("text"):setText(""):setPos(64,0,0)
end

function Frequency:update(strength)
    self.strength = strength
    self.text:setText(tostring(self.strength))
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
---@param strength integer
---@param frequencyFirst ItemStack
---@param frequencyLast ItemStack
function RedstoneLinks.updateReading(strength,frequencyFirst,frequencyLast)
    
end

