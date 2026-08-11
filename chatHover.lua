
-- require "wheelCompass"

CHAT_MESSAGE = nil

MESSAGE_TIME = 0

CHAT_SHOWN = false

local CHAT_TEXT

require"floatingToolUse" -- temp

local chatObj = Utils.ID.field.TestObject:newPart("chat"):setPos(PS*vec(0,-0.1,0))
Utils.ID.field.ChatText = chatObj

require("redo.Grab").addSelectableGenerate("ChatText")

CHAT_TEXT = 
        
    chatObj:newPart("billboard","BILLBOARD")
    :newText("text")
        :setScale(1/2)
        :setText("")
        :setSeeThrough(true)
        :setAlignment("CENTER")



function pings.sendChatMessage(msg)
    MESSAGE_TIME = client.getSystemTime()
    CHAT_MESSAGE = msg
    CHAT_TEXT:setText(msg)
    CHAT_SHOWN = true
end

function events.tick()
    if CHAT_SHOWN and client.getSystemTime() - MESSAGE_TIME > 1000*10 then
        CHAT_TEXT:setText("")
        CHAT_SHOWN = false
    end
end


function events.chat_send_message(msg)
    msg = string.gsub(msg,"\\n","\n") -- makes \n work
    if string.sub(msg,1,2) == "¤" then
        pings.sendChatMessage(string.sub(msg,3))
    else
        if string.sub(msg,1,1) ~= "/" then
            
            pings.sendChatMessage(msg)
        end
        return msg
    end
end