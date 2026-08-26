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

-- function Utils.table.getNest(tbl,path)
    
--     for w in string.gmatch(path,"[^%.]+") do
--         if type(tbl) == "table" then
--             tbl = tbl[w]
--         else
--             return nil
--         end
--     end
--     return tbl
    
-- end


function Utils.table.getNest(tbl,path)
    local tp = type(path)
    if tp == "string" then
        for w in string.gmatch(path,"[^%.]+") do
            if type(tbl) == "table" then
                tbl = tbl[w]
            else
                return nil
            end
        end
    elseif tp == "table" then
        for index, value in ipairs(path) do
            if type(tbl) == "table" then
                tbl = Utils.table.getNest(tbl,value)
            else
                return nil
            end
        end
    else
        return tbl[path]
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


local w = Invoke:register("display",function  (self, value, rest, plr)
    local w = self:materializeBranch(value.text)
    local o = self:materializeBranch(value.on or value.target)
    if not o then return end
    o
    :newText("text")
    :setText(tostring(w)):setSeeThrough(true)
        :setLight(15,15)
        :setWidth(PS*4*16)
        :setScale(1/4)
        :setOpacity(0.75)

end)
w:addDoc{
    text = "adds a TextTask to target with text",
    value = "{text=<text>, on=<target>}",
    types = {
        text = "string",
        on = "ModelPart"
    },
    alts = {
        on = {"target"}
    }
}

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


