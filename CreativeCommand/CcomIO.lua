
local Ccom = require"CreativeCommand.CreativeCommands"

local Coroutine = require"Coroutine"

Ccom.IO = {}


Ccom.IO.Types = {}


local intercept_sable_info_trigger_string = "$Found (%S)* sub%-levels%:^"

---comment
---@param con CoroutineConstructor
---@param count integer
function Ccom.IO.read_translate_with(con,count,match)
    for i = 1, count do
        con:add(
        ---@param raw string
        ---@param text string
        ---@param tbl table
        function (raw,text,tbl)
            if match then
                assert(string.find(tbl.translate,match))
            end
            Coroutine.vars[tbl.translate] = tbl.with
        end)
    end
    return con
end

--- the keys are formatted as string.find(tbl.translate,pattern)
---@param con CoroutineConstructor
---@param count integer
---@param pattern string
function Ccom.IO.read_translate_with_pattern(con,count,pattern)

    for i = 1, count do
        con:add(
        ---@param raw string
        ---@param text string
        ---@param tbl table
        function (raw,text,tbl)
            Coroutine.vars[assert(string.find(tbl.translate,pattern),tbl.translate .. " " .. pattern)] = tbl.with
            return table.unpack(tbl.with)
        end)
    end
    return con
end

--- returns nil if the pattern is no found.
---@param con CoroutineConstructor
---@param pattern string
---@param plain boolean?
function Ccom.IO.read_translate_with_matching_pattern(con, pattern,plain)
    con:add(
    ---@param raw string
    ---@param text string
    ---@param tbl table
    function (raw,text,tbl)
        -- if not tbl.translate then
        --     log("translate not present",raw,text,tbl)
        -- end
        if tbl.translate and string.find(tbl.translate,pattern,nil,plain) then
            return table.unpack(tbl.with)
        end
    end)
    
    return con
end

-- ---comment
-- ---@param translates string[]
-- function Ccom.IO.sable_info_element_like(translates)
--     local out = Coroutine.constructor()
--     for index, translate in ipairs(translates) do
--         out:add(
--         ---@param raw string
--         ---@param text string
--         ---@param tbl table
--         function (raw,text,tbl)
--             if tbl.translate == translate then

--             end
--         end)
--     end
-- end

    -- "commands.sable.info.name" 
    -- "commands.sable.info.position"
    -- "commands.sable.info.orientation"
    -- "commands.sable.info.mass"
    -- "commands.sable.info.linear_velocity"
    -- "commands.sable.info.angular_velocity"

local Intercept_sable_info_single = Coroutine.constructor()
Ccom.IO.read_translate_with(Intercept_sable_info_single,6,"commands%.sable%.info%.(.*)")
:pipe():add(function (...)
    logTable(Coroutine.vars,3)
end)



local Intercept_sable_info = Coroutine.constructor()
Ccom.IO.read_translate_with_matching_pattern(Intercept_sable_info,"commands.sable.info.count",true)

:pipe()
:rep(Intercept_sable_info_single)
:pipe()
-- :add(function (...)
--     log("finished sable info coroutine",...)
-- end)

Ccom.IO.Types.Intercept_sable_info = Intercept_sable_info






---checked for all messages when there is an interception active
-- function Intercept_sable_info.trigger(raw,text)
--     local count = string.find(text,Intercept_sable_info.trigger_string)
--     if count then


--     end
    

-- end


function Ccom.IO.await()
    
end


local texts = ""

Ccom.IO.listen_next = false
Ccom.IO.copying = false

-- Utils.parts.child(models,"gui","GUI")
local gui = models:newPart("Ccom_gui","GUI")
local center_text = gui:newText("center_text"):setPos(client.getScaledWindowSize().x__/(-2)):setWidth(client.getScaledWindowSize().x/2)


function Ccom.IO.write_text_center(text)
    center_text:setText(text or "")
end


local thread = Intercept_sable_info:instance()



--- raw is
function Ccom.IO.chat_receive_message(raw,text)
    -- host:setActionbar(raw)

    if Ccom.IO.copying then
        texts = texts .. "\1" .. text .. "\n\2" .. (raw) .. "\n"
    end
    -- Ccom.IO.write_text_center(toJson(raw))
    if Ccom.IO.listen_next then
        -- log("CHAT:",raw,text)
        logTable(parseJson(text),4)
        Ccom.IO.listen_next = false
    end
    
    local tbl = parseJson(text)

    local res, a = thread:resume(raw,text,tbl)
    if not res then
        thread = Intercept_sable_info:instance()
    end

    -- return toJson(text)
end
function Ccom.IO.copy_last()
    -- host:setActionbar(raw)
    host:setClipboard(texts)
    texts = ""
end

-- events.CHAT_RECEIVE_MESSAGE:register(Ccom.IO.chat_receive_message)

return Ccom.IO