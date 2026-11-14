Pinned = {}

---comment
---@param index integer
---@param msg HostAPI.chatMessage?
function Pinned.setChatMessage(index, msg)
    if msg then
        host:setChatMessage(index, msg.json, vectors.intToRGB(msg.background))
    else
        host:setChatMessage(index, nil)
    end
end


---comment
---@param a integer
---@param b integer
---@param func_a? fun()
function Pinned.swapMessages(a, b, func_a)
    local msg_a = host:getChatMessage(a)
    local msg_b = host:getChatMessage(b)
    Pinned.setChatMessage(a,msg_b)
    Pinned.setChatMessage(b,msg_a)
end


Pinned.chat_message_marker_start = "okko_chat_message_marker|"
Pinned.disabled_chat_message_marker_start = "okko_DISABLED_chat_message_marker|"

---comment
---@param marker string
---@return HostAPI.chatMessage? message
---@return integer index
function Pinned.find_message(marker)
    local i = 0
    while true do
        i = i + 1
        local msg = host:getChatMessage(i)
        if not msg then
            return nil, i
        end
        if string.find(msg.json, marker, 1, true) then
            return msg, i
        end
    end
end

---it wouldn't do for a chat message to quote another chat message's marker, so pass them through this
---@param str string
---@return string
---@return number
function Pinned.strip_chat_message_marker(str)
    return string.gsub(str, Pinned.chat_message_marker_start, Pinned.disabled_chat_message_marker_start)
end
function Pinned.marker_make(uuid)
    return Pinned.chat_message_marker_start .. uuid .. "|"
end





---finds the marker in the string.
---@param str string
---@return string? whole
---@return string main
---@return string uuid
---@return string action
function Pinned.marker_get(str)
    return string.match(str, "(("..Pinned.chat_message_marker_start .. "([^|]*)|)([^|]*)|?)")
end



function Pinned.menu(message,json)

    local uuid = client.intUUIDToString(client.generateUUID())

    local marker = Pinned.marker_make(uuid)

    local j = {
        
        insertion = marker .. "menu_insertion|",
        text = "",
        extra = {
            -- {

            --     clickEvent = {
            --         action = "suggest_command",
            --         value = marker .. "expand|"
            --     },
            --     hoverEvent = {
            --         contents = {
            --             text = "marker"
            --         },
            --         action = "show_text"
            --     },
            --     text = "|",
            --     color = "#27DD27"
            -- },
            {
                clickEvent = {
                    action = "copy_to_clipboard",
                    value = message
                },
                hoverEvent = {
                    contents = {
                        text = "copy"
                    },
                    action = "show_text"
                },
                text = "|",
                color = "#27DD5E"
            },
            {
                clickEvent = {
                    action = "copy_to_clipboard",
                    value = json
                },
                hoverEvent = {
                    contents = {
                        text = json
                    },
                    action = "show_text"
                },
                text = "|",
                color = "#27D1DD"
            }
        }
    }
    local w = toJson(j)
    -- w = toJson({
    --             type= "object",
    --             object = "player",
    --             player = "okkokko"
    --         })

    if not Utils.string.correctlyFormatted(w, 100) then
        printJson(w, "\n")
        error("incorrectly formatted")
        return
    end
    return w,marker,uuid
    
end






---@param message? string
---@param json? string
---@return string|false? replace
---@return Vector3? bgcolor
function Pinned.chat_receive_message(message, json)
    if Pinned.inactive then
        return
    end
    if not json then
        return
    end
    assert(message)
    ---@cast json -?

    json = Pinned.strip_chat_message_marker(json)

    local w = Pinned.menu(message,json)
    if not w then
        return
    end

    return ('{"extra":[%s,%s], "text":""}'):format(w, json)
end



---comment
---@param modified_json string
function Pinned.separate_json(modified_json)
    local extra = parseJson(modified_json).extra
    local out_menu = {}
    local i = 1
    while Pinned.marker_get(extra[i].insertion or "") do
        table.insert(out_menu,extra[i])
        i = i + 1
    end
    local out_message = {}
    for j = i, #extra do
        table.insert(out_message,extra[j])
    end
    return out_menu,out_message



    
end

-- ---comment
-- ---@param index any
-- ---@param message HostAPI.chatMessage?
-- function Pinned.expand(index,message)
--     message = message or assert(host:getChatMessage(index))
    
--     host:setClipboard(message.json)
--     local prs = parseJson(message.json)
--     -- logTable(prs,5)


--     -- host:setChatMessage(index,toJson({extra=extra,text=""}))
--     -- host:setChatMessage(index)
--     host:setChatMessage(index,message.json)
-- end


Pinned.actions = {}

---@param message HostAPI.chatMessage
---@param index integer
---@param menu table
---@param extra table
function Pinned.actions.menu_insertion(message,index,menu,extra)

    printJson("testing")
    printJson(Pinned.separator)
    printJson("end")

    
end

--- todo: hides the message,
---@param message HostAPI.chatMessage
---@param index integer
---@param menu table
---@param extra table
function Pinned.actions.collapse(message,index,menu,extra)
    
end
---@param message HostAPI.chatMessage
---@param index integer
---@param menu table
---@param extra table
function Pinned.actions.uncollapse(message,index,menu,extra)
    
end


--- string that moves the text after it to a new printJson
Pinned.separator = "okko.separator"


---@param message? string
---@param json? string
---@return string|false? replace
---@return Vector3? bgcolor
function Pinned.do_separator_chat_receive_message(message, json)
    if not json then
        return
    end
    ---@cast json -?

    local prs = parseJson(json)
    local extra = prs.extra
    if not extra then return end

    for index, value in ipairs(extra) do
        if Pinned.separator  == value then
            local start = Utils.table.move(extra,1,index - 1,1,{})
            local rest = Utils.table.move(extra,index+1,#extra,1,{})
            prs.extra = start
            local startJ = toJson(prs)
            if #rest > 0 then
                prs.extra = rest
                local restJ = toJson(prs)
                printJson(restJ)
            end
            return startJ
        end
    end
end


---comment
---@param main string
---@param action string
function Pinned.onMarker(main,action)
    local message, index = Pinned.find_message(main)
    if not message then
        log("message not found")
    end
    ---@cast message -?
    -- printJson(main,"\n",action,"\n at ",index," \n",message.json,"\n")
    
    local menu,extra = Pinned.separate_json(message.json)
    local f = Pinned.actions[action]
    if f then
        f(message,index,menu,extra)
    end
end


---@type string?
local old_text = nil
function Pinned.render()
    local txt = host:getChatText()
    if txt then
        local marker,main,uuid,action = Pinned.marker_get(txt)
        if marker then
            
            host:setChatText(old_text or "")
            Pinned.onMarker(main,action)
            return
        end
    end
    old_text = txt
end

if host:isHost() then
    events.CHAT_RECEIVE_MESSAGE:register(Pinned.chat_receive_message)
    events.CHAT_RECEIVE_MESSAGE:register(Pinned.do_separator_chat_receive_message)
    events.WORLD_RENDER:register(Pinned.render)
end
