
local Ccom = require"CreativeCommand.CreativeCommands"


---comment
---@param message string
function Ccom.substitute_message(message,fake)
    if type(message) ~= "string" then return message end
    local function loo(a)
        return Loadstring("return "..a,nil)
    end
    -- local q = _ENV

    -- local modified = string.gsub(message,"%$(%b{})", function (b)
    --     local a = string.sub(b,2,-2)
    local modified = string.gsub(message,"!#(.-)#!", function (a)
        -- local a = string.sub(b,2,-2)
        local w,dots,res = string.match(a,"^(.-)([%.%:]+)([%w_]*)$")
        if res == "" then
            a = w
        else
            -- log("res:",w,dots,res)
        end
        local c, q = loo(a)
        if fake and w and not c and string.find(q,"function arguments expected") then
            c,q = loo(w)
        end

        if c then
            local r, s = pcall(c)
            if w then
                return logTable(s,string.len(dots or " "),true)
            end
            
            if r or true then
                return tostring(s)
            end
        else
            return tostring(q)
        end

    end)
    -- log("last message:",host:getChatMessage(1))
    if not fake then
        host:appendChatHistory(message)
    end
    return modified
end





local prev_chat_text = nil

function Ccom.chatTextPreview (force)
    local tx = host:getChatText()
    if (force == "force") or prev_chat_text ~=tx then
        prev_chat_text = tx
        if not tx then
            Ccom.IO.write_text_center(nil)
            return
        end
        
        local modif = Ccom.substitute_message(tx,true)
        Ccom.IO.write_text_center(modif)
        

    end
    -- if not tx then return end
    -- local modif = Ccom.substitute_message(tx,true)

    -- local chng = false
    -- local ntx = string.gsub(tx,"#([^#]*)#",function (b)
    --     chng = true
    --     return "("..b..")"
    -- end)
    -- if chng then
    --     host:setChatText(ntx)
    -- end

end

local evaluate_key = keybinds:newKeybind("evaluate open chat","key.keyboard.grave.accent",true)

function evaluate_key.press(mod,self)
    Ccom.chatTextPreview("force")
end



-- events.world_render:register(Ccom.chatTextPreview)
