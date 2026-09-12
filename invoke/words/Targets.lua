require"invoke.Invoke"




Invoke:registerKeyword("plr", function (self,tbl, rest, plr)
    if rest == "" then
        return plr
    else
        return world.getPlayers()[rest]
    end
end)

--- deprecated. this should be a filter. also should be Infos
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
    
    if rest == "pos" then
        return centerPos
    end
    -- return rest
    


end)

Invoke:register("Entities",function (self, value, rest, plr)
    local entities = world.getEntities(-10000,-10000,-10000,10000,10000,10000)
    local out = {}
    for index, e in ipairs(entities) do
        if ((value.living == nil) or value.living == e:isLiving()) or (value.type == nil or value.type == e:getType()) then
            out[#out+1] = e
        end
    end
    return out
end)


Invoke:register("call",function (self, value, rest, plr)
    -- if rest == "getVariable" then
    --     return
    -- end
    if rest == "" then
        return
    end
    local p = self:materializeBranch(value)
    if p and type(p) ~= "table" and type(p[rest]) =="function" then
        return p[rest](p)
    end

end):addDoc{
    text = "calls <value>:<rest>()"
}