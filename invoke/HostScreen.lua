--- puts the result of host:getScreen() into avatarVars, in a shortened form.




local HostScreen = {}

HostScreen.ENABLE = true


--- overrideable
---@type {[string] : boolean?}|fun(string):boolean
HostScreen.FILTER = {
    ["net.minecraft.client.gui.screens.inventory.BookEditScreen"] = true,
}
--- overrideable
---@type "WHITELIST"|"BLACKLIST"|"ALL"|"NONE"
HostScreen.FILTER_MODE = "WHITELIST"

--- overrideable
--- if true, a screen that is blocked by the filter is shown as `"UNKNOWN"`. otherwise it is shown as `false`, same as not being on a screen.
--- generally set this to false to reduce pings
---@type boolean
HostScreen.DIFFERENTIATE_UNKNOWN_AND_NONE = false


HostScreen.varkey = "host:getScreen()"
HostScreen.unknown_key = "UNKNOWN"



---takes the part after the last .
---@param id string|nil|false
---@return string|nil|false
function HostScreen.makeLaconic(id)
    if id then
        local _, _, w = string.find(id,"([^%.]*)$")
        return w
    else
        return id
    end
end


function HostScreen.get(plr)
    if plr == HostScreen then
        plr = avatar:getUUID()
    elseif type(plr) ~= "string" then
        local succ
        succ, plr = pcall(plr.getUUID,plr)
        if not succ then return end
    end
    local w = (world.avatarVars()[plr] or {})[HostScreen.varkey]
    if type(w) == "string" then
        return ("%s"):format(w) -- just in case the var is malicious and lying about being a string
    elseif w == false then
        return false
    end
end

function HostScreen.getLaconic(plr)
    return HostScreen.makeLaconic(HostScreen.get(plr))
end

function HostScreen.is(plr,screen)
    return HostScreen.get(plr) == screen
    
end

--- unimplemented: you can implement it yourself later.
function HostScreen.pack(id)
    return id
end
function HostScreen.unpack(key)
    return key
end

function pings.setHostScreen(id)
    avatar:store(HostScreen.varkey,HostScreen.unpack(id))
end


if host:isHost() and HostScreen.ENABLE then

    HostScreen.current = false

    function HostScreen.filtered(screen)
        if not screen then
            return false
        end
        if screen == "MODE_" then -- let's just block this edge case
            return false
        end
        if (HostScreen.FILTER_MODE == "NONE") then
            return false
        end

        if (HostScreen.FILTER_MODE == "ALL")
        or (type(HostScreen.FILTER) == "function" and HostScreen.FILTER(screen))
        or (type(HostScreen.FILTER) == "table" and ((not HostScreen.FILTER[screen]) == (HostScreen.FILTER_MODE == "BLACKLIST")))
        then
            return screen
        end
        return HostScreen.DIFFERENTIATE_UNKNOWN_AND_NONE and HostScreen.unknown_key
    end

    function HostScreen.update()
        local screen = host:getScreen()
        local screenF = HostScreen.filtered(screen)
        local screenL = HostScreen.makeLaconic(screenF)
        if HostScreen.current ~= screenF then
            HostScreen.current = screenF
            pings.setHostScreen(screenL)
        end

    end

    events.TICK:register(HostScreen.update)
end

return HostScreen