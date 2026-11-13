
local Ccom = require"CreativeCommand.CreativeCommands"


Ccom.macros = {}

Ccom.macros.command_starter = "%!%%"

Ccom.macros.recording = nil

Ccom.macros.macros = {}


Ccom.macros.functions = {}

function Ccom.macros.functions.DEF(rest)
    if Ccom.macros.functions[rest] then
        log("cannot overload ".. rest)
    end
    local out = {}
    Ccom.macros.recording = out
    Ccom.macros.macros[rest] = out
end

function Ccom.macros.functions.END(rest)
    Ccom.macros.recording = nil
end

function Ccom.macros.functions.UNDO(rest)
    if Ccom.macros.recording then
        Ccom.macros.recording[#Ccom.macros.recording] = nil
    end
end
function Ccom.macros.functions.VIEW(rest)
    logTable(Ccom.macros.macros[rest] or Ccom.macros.recording or Ccom.macros.macros,3)
end

function Ccom.macros.functions.SAVE(rest)
    config:setName("macros"):save("macros",Ccom.macros.macros)
    log("saved macros")
end
function Ccom.macros.functions.LOAD(rest)
    Ccom.macros.macros = config:setName("macros"):load("macros") or {}
end
Ccom.macros.functions.LOAD()

function Ccom.macros.record(message)
    
    if Ccom.macros.recording then
        table.insert(Ccom.macros.recording,message)
    end
end

function Ccom.macros.execute(macro)
    if not macro then
        return
    end
    for index, value in ipairs(macro) do
        local com = Ccom.substitute_message(value,true)
        if com then
            Ccom.sendChatCommand(com)
        end
    end
end

---comment
---@param message string
function Ccom.macros.macro_send_message(message)
    if type(message) ~= "string" then return message end

    local word,rest = message:match("^"..Ccom.macros.command_starter .."%s*(%S*)(.*)")
    if word then
        local f = Ccom.macros.functions[word]
        if f then
            local r,r2 = rest:match("%s*(%S*)(.*)")
            return f(r,r2)
        else
            local macro = Ccom.macros.macros[word]
            if macro then
                -- putting substitutable values after the macro name is possible
                local subst = Ccom.substitute_message(rest,true)
                Ccom.macros.execute(macro)

            end
        end
    end
    -- should record running macros.macros but not macros.functions
    Ccom.macros.record(message)


    return message


end




return Ccom.macros