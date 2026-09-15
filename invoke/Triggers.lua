
require"invoke.Invoke"


local playerTrackedMetatable = {
}

local playerTrackedFunctions = {}

--- the absolute value signifies how long the condition is been the same, with 1 meaning it changed this tick
--- the sign signifies whether it is on or off
--- nil means it's uninitialized.

function playerTrackedFunctions.update(old,truth)
    if not old then
        old = 0
    end
    if truth then
        if old < 0 then
            old = 0
        end
        return old + 1
    else
        
        if old > 0 then
            old = 0
        end
        return old - 1
    end 
end
function playerTrackedFunctions.active(val)
    return val and val > 0
    
end

function playerTrackedFunctions.inactive(val)
    return val and val < 0
end


function playerTrackedFunctions.started(val)
    return val == 1
end

function playerTrackedFunctions.stopped(val)
    return val == -1
end
function playerTrackedFunctions.changed(val)
    return (val == -1) or (val == 1)
end

function playerTrackedMetatable:update(plr,truth)
    
    
    local name = plr:getUUID()
    self[name] = playerTrackedFunctions.update(self[name],truth)
end


function playerTrackedMetatable:active(plr)
    if not plr:isLoaded() then return end
    return playerTrackedFunctions.active(self[plr:getUUID()])
end

function playerTrackedMetatable:inactive(plr)
    if not plr:isLoaded() then return end
    return playerTrackedFunctions.inactive(self[plr:getUUID()])
end


function playerTrackedMetatable:started(plr)
    if not plr:isLoaded() then return end
    return playerTrackedFunctions.started(self[plr:getUUID()])
end

function playerTrackedMetatable:stopped(plr)
    if not plr:isLoaded() then return end
    return playerTrackedFunctions.stopped(self[plr:getUUID()])
end
function playerTrackedMetatable:changed(plr)
    if not plr:isLoaded() then return end
    return playerTrackedFunctions.changed(self[plr:getUUID()])
end

playerTrackedMetatable.__index = playerTrackedMetatable




--- todo: a way to make any trigger. on a global page, maketrigger.sprint <| call.isSprinting = Holder


Invoke.playerTrackedFuncs = {}
Invoke.triggers = {}
---comment
---@param key string
---@param func fun(plr:Entity):boolean
function Invoke.registerPlayerTracked(key,func)
    Invoke.playerTrackedFuncs[key] = func
    Invoke.triggers[key] = setmetatable({},playerTrackedMetatable)
    
    func = nil
    local w =  Invoke.triggers[key]
end

--- func shouldn't make use of value
---@param key string
---@param func fun(self:Invoke,value:table,rest:string):...
---@return FunctionDoc
function Invoke:registerCondition(key,func)
    return self:registerOld(key,function (self, value, rest)
        local r = func(self,value,rest)
        if r then
            if value == nil then
                return true
            else
                return self:materializeBranch(value)
            end
        else
            return false
        end
    end)
end


Invoke:registerByName("cond",function (self, value, rest)
    local r = self:materializeBranch(rest)
        if r then
            if value == nil then
                return true
            else
                return self:materializeBranch(value)
            end
        else
            return false
        end
end)

Invoke:registerOnlyRest("on",function  (self, rest)
    if Invoke.triggers[rest] then
        if Invoke.triggers[rest]:started(self.plr) then
            return true
        end
    else
        if playerTrackedFunctions.started(self:getVariable(rest)) then 
            return true
        end
    end
    end)
:setSection("triggers")

Invoke:registerOnlyRest("while",function  (self, rest)
    if Invoke.triggers[rest] then 
        if Invoke.triggers[rest]:active(self.plr) then
            return true
        end
    else
        if playerTrackedFunctions.active(self:getVariable(rest)) then 
            return true
        end
    end
end)
:setSection("triggers")
Invoke:registerOnlyRest("unless",function  (self, rest)
    if Invoke.triggers[rest] then 
        if Invoke.triggers[rest]:inactive(self.plr) then
            return true
        end
    else
        if playerTrackedFunctions.inactive(self:getVariable(rest)) then 
            return true
        end
    end
end)
:setSection("triggers")
Invoke:registerOnlyRest("off",function  (self, rest)
    if Invoke.triggers[rest] then 
        if Invoke.triggers[rest]:stopped(self.plr) then
            return true
        end
    else
        if playerTrackedFunctions.stopped(self:getVariable(rest)) then 
            return true
        end
    end
end)
:setSection("triggers")

Invoke:registerOnlyRest("change",function  (self, rest)
    if Invoke.triggers[rest] then 
        if Invoke.triggers[rest]:changed(self.plr) then
            return true
        end
    else
        if playerTrackedFunctions.changed(self:getVariable(rest)) then 
            return true
        end
    end
end)
:setSection("triggers")


-- todo: when something is suddenly over some value. hm, could be achieved with a second maketrigger comparing the variable of the first


function Invoke.updatePlayerTracked(players)
    
    local players = players or world.getPlayers()
    for name, plr in pairs(players) do
        if plr:isLoaded() then
            local name = plr:getUUID()
            for key, func in pairs(Invoke.playerTrackedFuncs) do
                Invoke.triggers[key]:update(plr,func(plr))
            end
        end
    end
end

Invoke.registerPlayerTracked("sneak",figuraMetatables.EntityAPI.__index.isSneaking)

local Writing = require"invoke.Writing"

Invoke.registerPlayerTracked("offhand",function (plr)
    local item = plr:getItem(2)
    return Writing.isWritingItem(item,plr)
end)

Invoke.registerPlayerTracked("open",function (plr)
    local w = Invoke.extract(plr,1) or Invoke.extract(plr,2)
    -- log(w, w and w:isOpen())
    return w and w:isOpen()
end)


Invoke:registerByValue("maketrigger",function (self, rest, input)
    self:setVariable(rest,playerTrackedFunctions.update(self:getVariable(rest),input))
end):addAlternateNames("updatetrigger"):addDoc{
    text = "updates a trigger variable, to be used with on/off/while/unless/change",
    rest = "variable name",
    value = "on/off"
}


--[[
invoke okkokko gsub={p="^%s*>>",r="invoke okkokko "}
; >> gsub = {p="%-%-(.*)$",r=""}
;
>> gsub ={ p="<|(.*)$", r="={ %1 }",rec=true}

invoke okkokko gsub={p="^%s*>>",r="invoke okkokko "}
;>> gsub.freeze ={ p="$", r="ö"}
;>> gsub ={ p="([%]}])", r="ö%1"}
;>> gsub ={ p="([%[{])", r="%1ä"}
;>> gsub ={ p="<|(.-%bäö.-)ö", r="={ä %1 ö}",rec=true}
;>> gsub.unfreeze ={ p="[äö]", r=""}


@`

invoke okkokko gsub={p="^%s*>>",r="invoke okkokko "}
;>> gsub.freeze ={ p="$", r="`"}
;>> gsub ={ p="([%]}])", r="`%1"}
;>> gsub ={ p="([%[{])", r="%1@"}
;>> gsub ={ p="<|(.-%b@`.-`)", r="={@ %1 `}",rec=true}
;>> gsub.unfreeze ={ p="[@`]", r=""}


invoke okkokko gsub={p="^%s*>>",r="invoke okkokko "}
;>> gsub.freeze ={ p="$", r="`"}
;>> gsub ={ p="([%]}])", r="`%1"}
;>> gsub ={ p="([%[{])", r="%1@"}
;>> gsub ={ p="<|(.-`)", r="={ %1 `}",rec=true}
;>> gsub.unfreeze ={ p="[@`]", r=""}



invoke okkokko gsub={p="^%s*>>",r="invoke okkokko "}
;>> gsub ={ p="<|(.*)$", r="={ %1 }",rec=true}
;>> gsub = {p='SL%s*=%s*(%b{})',r= ' sub={r=",\n",p=",",s=%1}'}



]]
