require"invoke.Invoke"




Invoke:registerKeyword("plr", function (self,tbl, rest)
    if rest == "" then
        return plr
    else
        return world.getPlayers()[rest]
    end
end)

--- deprecated. this should be a filter. also should be Infos
Invoke:registerKeyword("All", function (self,tbl, rest)
    if type(tbl) == "table" then
        local radius = tbl.within or tbl.radius
        local center = (not tbl.center) and self.plr or self:materializeBranch(tbl.center)
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

--- value is now User by default but can be changed
Invoke:registerKeyword("PickBlock",function (self, tbl, rest)
    local plr
    if tbl then
        plr = self:materializeBranch(tbl)
        if not plr then return end
    else
        plr = self.plr
    end
    local block, hitPos, side = plr:getTargetedBlock()
    local centerPos = block:getPos()
    if not block then return end
    if rest == "" then
        return block
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
    
    if rest == "pos" then
        return centerPos
    end
    -- return rest
    


end)

Invoke:registerOld("Entities",function (self, value, rest)
    local entities = world.getEntities(-10000,-10000,-10000,10000,10000,10000)
    -- if value.type then
    --     log("type:",value)
    -- end
    -- log(value)
    if type(value) ~= "table" then
        return entities
    end
    local out = {}
    for index, e in ipairs(entities) do
        if ((value.living == nil) or value.living == e:isLiving()) and (value.type == nil or value.type == e:getType()) then
            out[index] = e
        end
    end
    return out
end)

Invoke:registerKeyword("User",function (self)
    return self.plr:isLoaded() and self.plr
end)



Invoke:registerByValue("call",function (self, rest, input)
    local start,sep, vars = string.match(rest,"^(%a*)(%s*)(.*)$")
    -- log(start,vars)
    if not start then
        error("call: not parsed: " .. rest)
        return
    end
    if start == "getVariable" then
        return
    end
    if start == "" then
        return
    end

    local p = input
    if p and type(p) ~= "table" and type(p[start]) =="function" then -- not table, so that actual lists can't be passed onto functions they contain.
    
        
        if sep ~= "" then
            local vars3 = parseJson("[" .. vars .. "]")
            -- log(vars3)
            return p[start](p,table.unpack(vars3))
        else
            return p[start](p)
        end    
    else
        error(("no method %s found on type %s"):format(start,type(p)))
    end

end):addDoc{
    text = "calls <value>:<rest>()"
}

--- wait, I could just use call.getTargetedEntity
Invoke:registerKeyword("PickEntity",function (self, tbl, rest)
    local plr
    if tbl then
        plr = self:materializeBranch(tbl)
        if not plr then return end
    else
        plr = self.plr
    end
    local ent, hitPos = plr:getTargetedEntity()
    if rest == "pos" then
        return hitPos
    end
    return ent
end)