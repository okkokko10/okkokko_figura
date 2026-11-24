

-- require"DrawLine"


---@class Plot
---@field part ModelPart
---@field pointer integer
---@field name string?
---@field scale number?
Plot = {}
Plot.__index = Plot


-- Plot.buffer = data:createBuffer()

---@type ModelPart[]
Plot.parts = {}

Plot.size = 100

Plot.prefab = models:newPart("PlotPrefab"):remove()
Plot.prefab:newPart("child"):newText("text"):setText(".")
-- Plot.prefab.child:newBlock("block"):setBlock("minecraft:cyan_wool")



---comment
---@param part ModelPart
---@return Plot plot
function Plot.new(part,name, prefab)

    local out = setmetatable({part = part, name= name, parts = {}, pointer = 1, prefab = prefab},Plot)
    out:init()
    return out

end



function Plot:init()
    for i = 1, self.size do
        local p = Plot.prefab:copy((self.name or "")..tostring(i))
        self.parts[i] = p
        self.part:addChild(p)
    end
end

function Plot:write(value)
    local p = self.parts[self.pointer]
    if p then
        p:setPos((value or 0) * (self.scale or 1), self.pointer, 0)
    end
    self.pointer = (self.pointer % self.size) + 1
    
end
