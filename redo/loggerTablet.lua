





local page = require"redo.ActionWheel2"


local oldLog = log



local LogText = Positioning.parts.PlayerFollower:newPart("LogText"):setPos(PS*1,PS/2,PS*3)
Utils.ID.field.LogText = LogText

local rect = Rect.fromEndpoints(vec(0,0,0),PS*vec(-1,1,1/PS))

local it = LogText:newItem("Item"):setItem("minecraft:glass")
rect:setCenteredItemTo(it)

local logText = LogText:newText("text"):setSeeThrough(true):setScale(1/4)

local history = ""

local function newLog(...)
    oldLog(...)
    local out = "\n"
    for index, value in ipairs({...}) do
        out = out .. "    " .. tostring(value)
    end
    history = out .. history
    logText:setText(history)
end

log = newLog


require("redo.Grab").addSelectableGenerate("LogText")