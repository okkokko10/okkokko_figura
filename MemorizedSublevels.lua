



local MemorizedSublevels = {}

MemorizedSublevels.filename = "memorized_sublevels"


--- file structure for memorized_sublevels: 

local w = {
    trackeds = {{pos=vec(200000,0,200000),label="ship"}},
    ["ship"] = vec(200000,0,200000),
    [tostring(vec(200000,0,200000))] = {wpos=vec(200,70,52),time="2026:9:21:17:50"}
}


function MemorizedSublevels.addTracked(pos,label)
    
    -- local trackeds = config:name(MemorizedSublevels.filename):load("trackeds") or json.newArray()
    -- local w = json.newObject()
    -- w:put("pos",pos)
    -- w:put("label",label)
    -- trackeds:add(w)

    local trackeds = config:name(MemorizedSublevels.filename):load("trackeds") or {}
    local w = {pos=pos,label=label}
    trackeds[#trackeds+1] = w
    config:name(MemorizedSublevels.filename):save("trackeds",trackeds)
    MemorizedSublevels.updateFollower(pos,vec3(0),label)
end

function MemorizedSublevels.currentTime()
    return client.getSystemTime()
end

function Utils.timestring(time)
    time = math.abs(time)
    local ms = time % 1000
    time = math.floor(time / 1000)
    local s = time % 60
    time = math.floor(time / 60)
    local min = time % 60
    time = math.floor(time / 60)
    local h = time % 24
    time = math.floor(time / 24)
    local d = time
    local str = ""

    for index, value in ipairs({{"ms",ms},{"s",s},{"min",min},{"h",h},{"d",d}}) do
        if value[2] ~= 0 then
            str = tostring(value[2]) .. value[1] .. str
        end
    end
    return str



end

function MemorizedSublevels.timeDifference(old)
    local diff = MemorizedSublevels.currentTime() - old
    return diff, Utils.timestring(diff)
end

function MemorizedSublevels.posIndex(pos)
    return tostring(pos)
end

function MemorizedSublevels.locate(label)
    
    local pos = config:name(MemorizedSublevels.filename):load(label)
    local info = config:name(MemorizedSublevels.filename):load(MemorizedSublevels.posIndex(pos))
    return info.wpos,MemorizedSublevels.timeDifference(info.time)
end


function MemorizedSublevels.updatePos(pos)
    
    local worldPos = Utils.Sublevel.sableSublevelToWorld(pos)
    if Utils.Sublevel.isInSublevel(worldPos) then
        return
    end
    config:name(MemorizedSublevels.filename):save(MemorizedSublevels.posIndex(pos),{wpos=worldPos,time=MemorizedSublevels.currentTime()})
    MemorizedSublevels.updateFollower(pos,worldPos)
end

function MemorizedSublevels.update()

    local trackeds = config:name(MemorizedSublevels.filename):load("trackeds") or {}
    for key, value in pairs(trackeds) do
        MemorizedSublevels.updatePos(value.pos)
    end
end



function MemorizedSublevels.locate(label)
    local pos = config:name(MemorizedSublevels.filename):load(label)
    local info = config:name(MemorizedSublevels.filename):load(MemorizedSublevels.posIndex(pos))
    if not info then return end
    return info.wpos,MemorizedSublevels.timeDifference(info.time)
end

MemorizedSublevels.followers = {}
MemorizedSublevels.root = models:newPart("memorized_sublevels_root","WORLD")

function MemorizedSublevels.initFollowers()
    Utils.ID.set(MemorizedSublevels.root,"memorized_sublevels")
    
    local all = config:name(MemorizedSublevels.filename):load()
    local trackeds = all.trackeds or {}
    for key, value in pairs(trackeds) do
        local ind = MemorizedSublevels.posIndex(value.pos)
        local wpos = (all[ind] or {}).wpos
        MemorizedSublevels.updateFollower(value.pos,wpos,value.label)
    end
end
function MemorizedSublevels.updateFollower(pos,worldPos,label)
    local ind = MemorizedSublevels.posIndex(pos)
    if not MemorizedSublevels.root[ind] then
        local q = MemorizedSublevels.root:newPart(ind)
        Utils.ID.set(q,"ms:"..(label or ind))
    end
    MemorizedSublevels.root[ind]:setPos(PS*worldPos)
end


if host:isHost() then
    events.TICK:register(MemorizedSublevels.update)    
    events.ENTITY_INIT:register(MemorizedSublevels.initFollowers)
end

function MemorizedSublevels.trackPick(label)
    local block = host:getPickBlock()
    if block then
        MemorizedSublevels.addTracked(block:getPos(),label)
    else
        log("no block selected")
    end
end

return MemorizedSublevels