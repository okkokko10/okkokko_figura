



--- when a player (or even a mob) has a clipboard in their hand,
--- it is read and parsed as commands.
--- 
--- each line is its own command
--- 
--- a checked line is disabled
--- 
--- visible in offhand, visible in mainhand, visible always
--- modes can be set for each page
--- generally only the currently open page is active, but pages can be imported as a command.
--- a page can also be set to not run when it is open, instead only when imported.


--- conditions: hold/offhand specific item, Sneak

---@alias ibool integer

---@class ClipboardLine
---@field text string
---@field icon table
---@field item_amount number
---@field checked ibool

---@class ClipboardContent
---@field pages ClipboardLine[][]
---@field type string
---@field read_only ibool
---@field previously_opened_page integer




local Invoke = {}


---comment
---@param entity Entity
function Invoke:extract(entity)
    local item = entity:getItem(1)
    if item.id ~= "create:clipboard" then return end
    local content = item.tag["create:clipboard_content"]
    return content


end

--- uses parseJson with surrounding {} added
--- invoke okkokko action = Store, target = PickBlock, updateOn=Sneak, repeat=rise, key=["blocks",NEXT]
--- invoke okkokko action = Clear, target = [Store,"blocks",ALL] -- clears the stored blocks.
--- invoke okkokko action = ShowData, target = [Store,"blocks",ALL]
--- invoke okkokko action = Clear, target = PickInfo -- removes the info.
--- 

Invoke.hostname = "okkokko"


---comment
---@param text string
function Invoke:parse_line(text)
    if type(text) ~= "string" then
        return
    end
    local _, _, minus, name, rest = string.find(text,"(%-?)invoke%s+(%S*)%s+(.*)$")
    if not rest then return end
    if name ~= Invoke.hostname then
        return
    end
    if minus ~= "" then
        -- private. exit if not the client holding this.
    end

    local succ, dt = pcall(parseJson,"{"..rest.."}")
    if succ then
        return dt
    else
        logTable(dt)
    end
end

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


Invoke.infosPart = models:newPart("infos","World")

Invoke.infos = {}

function Invoke:createInfo(pos,text,plr)
    local str = tostring(pos)
    if self.infos[str] then
        self.infos[str]:remove()
        self.infos[str] = nil
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

    self.infos[str] = p
    p:newPart("bill","BILLBOARD"):newText("text")
    :setText(tostring(text)):setSeeThrough(true)
        :setLight(15,15)
        :setWidth(16*4*3)
        :setScale(1/4)
        :setOpacity(0.75)
end

function Invoke:execute(data,plr)
    -- logTable(data)
    if data.updateOn == "Sneak" then
    end
    if not Invoke.startedSneaking(plr) then
        return
    end

    if data.clear == "PickBlock" then
        
        local block, hitPos, side = plr:getTargetedBlock()
        if block then
            Invoke:createInfo(block:getPos(),nil,plr)
        end
    end
    if data.clear == "All" then
        for key, value in pairs(self.infos) do
            self:createInfo(key)
        end
    end

    if data.log then
        if data.log == "PickBlock" then
            local block, hitPos, side = plr:getTargetedBlock()
            if block then
                Invoke:createInfo(block:getPos(),block:toStateString(),plr)
                
                -- log(block:toStateString())
            end
        else
            -- logTable(data.log)
        end
    end
    
end

---comment
---@param content ClipboardContent
---@param plr Entity
function Invoke:contents(content,plr)
    if not content then return end
    if content.type ~= "written" then return end
    local pages = content.pages
    local page_index = content.previously_opened_page + 1
    local current_page = pages[page_index]
    if not current_page then
        logTable(content,4)
        return
    end
    for index, line in ipairs(current_page) do
        local text = line.text
        local checked = line.checked==1
        if not checked then
            local dt = Invoke:parse_line(text)
            if dt then 
                Invoke:execute(dt,plr)
            end
        end
    end

end


function Invoke.readPlayers()
    local players = world.getPlayers()
    for name, plr in pairs(players) do
        Invoke.updateSneaking(plr)
        local content = Invoke:extract(plr)
        if content then
            pcall(Invoke.contents,Invoke,content,plr)
            -- Invoke:contents(content,plr)
        end

    end
end


events.WORLD_TICK:register(Invoke.readPlayers)


events.SKULL_RENDER:register(function (delta, block, item)
    -- if block then
    --     Invoke:createInfo(block:getPos(),"okkokko's skull")
    -- end
    return Invoke.infosPart
end)
-- events.SKULL_RENDER:register(Invoke.readPlayers)


