
require"invoke.Invoke"


local playerTrackedMetatable = {
}

function playerTrackedMetatable:update(plr,truth)
    
    
    local name = plr:getUUID()
    if truth then
        self[name] = (self[name] or 0) + 1
    else
        if self[name] == 0 then
            self[name] = nil
        elseif self[name] ~= nil then
            self[name] = 0
        end
    end 
end


function playerTrackedMetatable:active(plr)
    if not plr:isLoaded() then
       return
    end
    local name = plr:getUUID()
    return self[name] ~= nil
end

function playerTrackedMetatable:inactive(plr)
    if not plr:isLoaded() then
       return
    end
    local name = plr:getUUID()
    return self[name] == nil
end


function playerTrackedMetatable:started(plr)
    if not plr:isLoaded() then
       return 
    end
    local name = plr:getUUID()
    return self[name] == 1
end

function playerTrackedMetatable:stopped(plr)
    if not plr:isLoaded() then
       return
    end
    local name = plr:getUUID()
    return self[name] == 0
end
function playerTrackedMetatable:changed(plr)
    if not plr:isLoaded() then
       return
    end
    local name = plr:getUUID()
    return (self[name] == 0) or (self[name] == 1)
end

playerTrackedMetatable.__index = playerTrackedMetatable


-- ---a function
-- ---@param key string
-- ---@param func fun(self:Invoke,value:table,plr:Entity):...
-- function Invoke:registerCondition(key,func)
--     Invoke:register(key,function (self, value, plr)
--         if func(self,value, plr) then
--             return self:materializeBranch(value,plr)
--         end
--     end)
-- end

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

Invoke:register("on",function  (self, value, rest, plr)
    if Invoke.triggers[rest] and Invoke.triggers[rest]:started(plr) then
        return (not value) or self:materializeBranch(value,plr)
    end
    end)
Invoke:register("while",function  (self, value, rest, plr)
    if Invoke.triggers[rest] and Invoke.triggers[rest]:active(plr) then
        return (not value) or self:materializeBranch(value,plr)
    end
end)
Invoke:register("unless",function  (self, value, rest, plr)
    if Invoke.triggers[rest] and Invoke.triggers[rest]:inactive(plr) then
        return (not value) or self:materializeBranch(value,plr)
    end
end)
Invoke:register("off",function  (self, value, rest, plr)
    if Invoke.triggers[rest] and Invoke.triggers[rest]:stopped(plr) then
        return (not value) or self:materializeBranch(value,plr)
    end
end)

Invoke:register("change",function  (self, value, rest, plr)
    if Invoke.triggers[rest] and Invoke.triggers[rest]:changed(plr) then
        return (not value) or self:materializeBranch(value,plr)
    end
end)

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

Invoke.registerPlayerTracked("offhand",function (plr)
    local item = plr:getItem(2)
    return item.id == "create:clipboard"
end)


-- Invoke:register("onSneak",function (self, value)
--     if Invoke.startedSneaking(self.plr) then
--         self:runTable(value,self.plr)
--     end
-- end)



Invoke:register("gsub",function (self, value, rest, plr)
    if rest == "freeze" then
        self:freezegsub()
    elseif rest == "unfreeze" then
        self:unfreezegsub()
    end
    
    local pattern = value[1] or value.pattern or value.p
    local repl = value[2] or value.repl or value.r
    local rec = value[3] or value.rec
    if type(pattern) == "string" and  type(repl) == "string" then
        self:addgsub(pattern,repl,nil,rec)
    end
end)




Invoke:registerKeyword("cancel",function  (self, value, rest, plr)
    if rest == "page" then
        self:cancelPage()
    else
        self:cancelEarly()
    end
end)


Invoke:register("and",function  (self, value, rest, plr)
    local out
    logTable(value,3)
    if type(value) == "table" then
        for index, value in ipairs(value) do
            out = self:materializeBranch(value,plr)
            log(index,out)
            if not out then
                break
            end
        end
    else
        log(type(value))
    end
    return out
end)

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
