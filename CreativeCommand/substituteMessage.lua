
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
        -- local w,dots,res = string.match(a,"^(.-)([%.%:]+)([%w_]*)$")
        local w,dots = string.match(a,"^(.-)([%.%:]+)%s*$")
        if w then
            a = w
        end
        local c, q = loo(a)
        -- if fake and w and not c and string.find(q,"function arguments expected") then
        --     c,q = loo(w)
        -- end

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


function Ccom.chatTextPreview (force,text)
    local tx = text or host:getChatText()
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

---@type string?
local latest = nil


---@return string?
local function getLatest()
    latest = latest or config:setName("substitution"):load("latest")
    return latest
end

---@param v string?
local function setLatest(v)
    latest = v or ""
    config:setName("substitution"):save("latest",latest)
end

local updating = false


function evaluate_key.press(mod,self)

    if bit32.btest(mod,1) then
        updating = not updating
        if mod == 1 then
            return
        end
    end

    
    local ct = host:getChatText()
    if bit32.btest(mod,2) then
        if host:isChatOpen() then
            if ct == "" then
                host:setChatText(getLatest() or "")
            else
                setLatest(ct)
            end
            return
        else
            ct = ""
        end
    elseif not host:isChatOpen() then
        ct = getLatest()
    end

    Ccom.chatTextPreview("force",ct)
    -- log(mod,self)
    if host:isChatOpen() then
        return
    end
end

local function evaluate_update(delta)
    if updating then
        Ccom.chatTextPreview("force",getLatest())
        
    end
end

events.world_render:register(evaluate_update)


-- events.world_render:register(Ccom.chatTextPreview)
