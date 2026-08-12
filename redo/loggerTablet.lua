





local page = require"redo.ActionWheel2"


local oldLog = log



local LogText = Positioning.parts.PlayerFollower:newPart("LogText"):setPos(PS*1,PS/2,PS*3)
Utils.ID.field.LogText = LogText

local rect = Rect.fromEndpoints(vec(0,0,0),PS*vec(-1,1,1/PS))

local it = LogText:newItem("Item"):setItem("minecraft:glass")
rect:setCenteredItemTo(it)

local logText = LogText:newText("text"):setSeeThrough(host:isHost()):setScale(1/4)

local history = ""

local oldLogTable = logTable

LOG_DISABLE = true

local function appendLogText(text,silent) 
    if silent then return text end
    history = text .. "\n" .. history
    logText:setText(history)
    return text
end

local function newLogTable(tbl,maxDepth,silent)
    return appendLogText(oldLogTable(tbl,maxDepth,silent or LOG_DISABLE),silent)
end


local function newLog(...)
    -- if select(1,...) == "SILENTLOG" then end
    if not LOG_DISABLE then
        oldLog(...)        
    end
    local out = ""
    for index, value in ipairs({...}) do
        out = out .. "    " .. tostring(value)
    end
    appendLogText(out)
end

log = newLog


require("redo.Grab").addSelectableGenerate("LogText")