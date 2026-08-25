require"invoke.Invoke"


-- Invoke.infosPart = models:newPart("infos","World")

Invoke.infos = {}
Invoke.infos_inverse = setmetatable({},{__mode="k"})



function Invoke:createInfo(pos,text,plr,ephemeral)
    local str = tostring(pos)
    local lis = self.infos
    -- if ephemeral then
    --     lis = self.ephemeral_infos
    -- end
    if lis[str] then
        lis[str]:remove()
        lis[str] = nil
    end
    if not text then
        return
    end
    if type(pos) ~= "Vector3" then
        return
    end
    self.counter = (self.counter or 0) + 1
    local p = Utils.Sublevel.moveToSublevelPosition((pos + 0.5),nil,Invoke.infosPart)
    -- local p = Invoke.infosPart:newPart(str .. "_"..self.counter):setPos((pos + 0.5)*PS)

    lis[str] = p
    p:newPart("bill","BILLBOARD"):newText("text")
    :setText(tostring(text)):setSeeThrough(true)
        :setLight(15,15)
        :setWidth(16*4*3)
        :setScale(1/4)
        :setOpacity(0.75)
end


function Invoke:getInfosDefault(key,fallback,...)
    if not self.infos[key] then
        self.infos[key] = fallback(...)
        self.infos_inverse[self.infos[key]] = key
    end
    return self.infos[key]
end

function Invoke:clearInfo(keyOrPart)
    keyOrPart = self.infos_inverse[keyOrPart] or keyOrPart
    if self.infos[keyOrPart] then
        self.infos[keyOrPart]:remove()
        self.infos[keyOrPart] = nil
    end
end


function Invoke:getInfos(pos)
    return self:getInfosDefault(tostring(pos),
        Utils.Sublevel.moveToSublevelPosition,(pos + 0.5),nil,self.infosPart)

end

function Utils.table.getNest(tbl,path)
    
    for w in string.gmatch(path,"[^%.]+") do
        if type(tbl) == "table" then
            tbl = tbl[w]
        else
            return nil
        end
    end
    return tbl
    
end

--- todo: instead of rest being the same as the assigned, have both. plr.okkokko={}

function Invoke:getPos(value)

    if type(value) == "ModelPart" then
        return value:partToWorldMatrix():apply(vec(0,0,0))
    else
        if value.isLoaded and value:isLoaded() then
            return value:getPos(client.getFrameTime())
        end
    end
end


Invoke:registerKeyword("plr", function (self,tbl, rest, plr)
    if rest == "" then
        return plr
    else
        return world.getPlayers()[rest]
    end
end)

--- deprecated. this should be a filter
Invoke:registerKeyword("All", function (self,tbl, rest, plr)
    if type(tbl) == "table" then
        local radius = tbl.within or tbl.radius
        local center = (not tbl.center) and plr or self:materializeBranch(tbl.center,plr)
        radius = radius * radius
        if type(radius) ~= "number" then return end
        local pos = self:getPos(center)
        local out = {}
        for key, value in pairs(self.infos) do
            local vpos = self:getPos(value)
            -- log(pos,vpos)
            if vpos and (pos-vpos):lengthSquared() < radius then
                out[key] = value
            end
        end
        return out

    else
        return self.infos
    end

end)


Invoke:registerKeyword("PickBlock",function (self, tbl, rest, plr)
    local block, hitPos, side = plr:getTargetedBlock()
    local centerPos = block:getPos()
    if not block then return end
    if rest == "" then
        return self:getInfos(centerPos)
    end
    if rest == "billboard" then
        -- local nm = tostring(centerPos)
        return self:getInfos(centerPos)
            :newPart("billboard","BILLBOARD")
    end
    if rest == "state" then
        return block:toStateString()
    end
    if rest == "side" then
        return self:getInfos(centerPos)
            :newPart("side"):setPos(PS*(hitPos - centerPos - 0.5)):setRot(Direction.toEulerAngles(side))
    end
    local _,_,re = string.find(rest,"nbt(.*)$")
    if re then
        local data = (block:getEntityData() or {}).BlockEntityTag
        return Utils.table.getNest(data,re)
    end
    if rest == "id" then
        return block.id
    end
    return rest
    


end)

Invoke:register("J",function (self,tbl, rest, plr)
    return toJson(self:materializeBranch(tbl))
    -- tostring(value)
end)

function Utils.table.getKeys(tbl)
    if not tbl then
        return nil
    end
    local out = {}
    for key, value in pairs(tbl) do
        out[#out+1] = key
    end
    return out
end

Invoke:register("K",function (self, value, rest, plr)
    return Utils.table.getKeys(self:materializeBranch(value))
    -- tostring(value)
end)




Invoke:register("sub",function  (self, value, rest, plr)
    local s = value[1] or value.s
    local pattern = value[2] or value.pattern or value.p
    local repl = value[3] or value.repl or value.r
    local rec = value[4] or value.rec
    local w = self:materializeBranch(s)
    if type(w) ~= "string" then return end
    return string.gsub(w,pattern,repl)
    
end)


Invoke:register("display",function  (self, value, rest, plr)
    local w = self:materializeBranch(value.text)
    local o = self:materializeBranch(value.on)
    if not o then return end
    o
    :newText("text")
    :setText(tostring(w)):setSeeThrough(true)
        :setLight(15,15)
        :setWidth(PS*4*16)
        :setScale(1/4)
        :setOpacity(0.75)

end)

Invoke:register("clear",function  (self, value, rest, plr)
    local w = self:materializeBranch(value)
    if type(w) == "table" then
        for key, value in pairs(w) do
            self:clearInfo(value)
        end
        
        
    end
    if type(w) == "ModelPart" then
        self:clearInfo(w)
    end

end)


Invoke:register("logJson",function  (self, value, rest, plr)
    logTable(value,5)
    -- return toJson(value)
end)


Invoke:register("rawJson",function  (self, value, rest, plr)
    return toJson(value)
end)

Invoke:register("text",function  (self, value, rest, plr)
    return rest or ""
end)


