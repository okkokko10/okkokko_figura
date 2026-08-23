
require"Invoke"


local areSneaking = {

}

function Invoke.updateSneaking(plr)
    if not plr:isLoaded() then 
       return 
    end
    local name = plr:getUUID()
    if plr:isCrouching() then
        areSneaking[name] = (areSneaking[name] or 0) + 1
    else
        if areSneaking[name] == 0 then
            areSneaking[name] = nil
        elseif areSneaking[name] ~= nil then
            areSneaking[name] = 0
        end
    end
end

function Invoke.startedSneaking(plr)
    if not plr:isLoaded() then 
       return 
    end
    local name = plr:getUUID()
    return areSneaking[name] == 1
end

function Invoke.stoppedSneaking(plr)
    if not plr:isLoaded() then 
       return 
    end
    local name = plr:getUUID()
    return areSneaking[name] == 0
end

function Invoke.sneaking(plr)
    if not plr:isLoaded() then
       return 
    end
    local name = plr:getUUID()
    return areSneaking[name] ~= nil
end
