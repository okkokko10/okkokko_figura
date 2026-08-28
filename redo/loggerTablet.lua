





local page = require"redo.ActionWheel2"


local oldLog = log



local LogText = Positioning.parts.MyBase:newPart("LogText"):setPos(PS*3,PS/2,-PS*1):setRot(0,90)
Utils.ID.field.LogText = LogText

local rect = Rect.fromEndpoints(vec(0,0,0),PS*vec(-1,1,1/PS))

local it = LogText:newItem("Item"):setItem("minecraft:glass")
rect:setCenteredItemTo(it)

local logText = LogText:newText("text"):setSeeThrough(host:isHost()):setScale(1/4)

local history = ""

local oldLogTable = logTable

LOG_DISABLE = false

local function appendLogText(text,silent) 
    if silent then return text end
    history = (text or "nil printed") .. "\n" .. history
    if history:len() > 10000 then
        history = string.sub(history,1,10000)
    end
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
logTable = newLogTable

function LogCurrentTime(extra)
    local date = client.getDate()
    log(("time log: %s:%s:%s"):format(date.hour,date.minute,date.second), extra)
    -- logTable(client.getDate())
end

pings.LogCurrentTime = LogCurrentTime

-- LogCurrentTime("init loggerTablet")

-- events.ENTITY_INIT:register(function ()
--     LogCurrentTime("entity_init")
-- end)

-- local tick_started = false
-- events.TICK:register(function ()
--     if not tick_started then
--         tick_started = true
--         LogCurrentTime("first tick")
--     end
-- end)


-- local world_tick_started = false
-- events.WORLD_TICK:register(function ()
--     if not world_tick_started then
--         world_tick_started = true
--         LogCurrentTime("first world tick")
--     end
-- end)


require("redo.Grab").addSelectableGenerate("LogText")