



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



---@class Invoke
---@field content ClipboardContent
---@field plr Entity
Invoke = {}

Invoke.__index = Invoke


function Invoke.newInstance(content,plr)
    return setmetatable({content=content,plr=plr},Invoke)
end

local Clipboard = {}

---should this line be ignored? by default whether there's a -- at the start.
---@param line string
function Clipboard:lineDisabled(line)
    return not not string.find(line,"^%s*%-%-")
end

function Clipboard:pageIter(index)
    local current_page = self.pages[index]
    if not current_page then
        return Utils.nop
    end
    local i = 0
    local f = Utils.nop
    return function ()
        local w = f()
        while w == nil do
            local line
            repeat
                i = i + 1
                line = current_page[i]
            until (not line) or line.checked ~= 1
            if not line then
                return
            end
            f = string.gmatch(line.text, "[^;]+")
            w = f()
        end

        return w
    end
end
function Clipboard:selectedPageIndex()
    return self.previously_opened_page + 1
    
end
function Clipboard:isOpen()
    return self.type ~= "written"
end




---comment
---@param entity Entity
function Invoke.extract(entity,slot)
    local item = entity:getItem(slot or 1)
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


--- todo: when a line is parsed wrong, the clipboard will stop execution until it is reopened

---comment
---@param text string
function Invoke:parse_line(text)
    if type(text) ~= "string" then
        self:logUnexpected("not text",type(text),text)
        return
    end
    local _, _, minus, name, rest = string.find(text,"^%s*(%-?)invoke%s+(%S*)%s+(.*)$")
    -- if not rest then
    --     _, _, minus, rest = string.find(text,"(%-?)%>%>%s+(.*)$")
    --     name = Invoke.hostname
    -- end
    -- log(text)
    if not rest then return end
    if name ~= Invoke.hostname and name ~= "*" then
        return
    end
    if minus ~= "" then
        -- private. exit if not the client holding this.
    end

    local succ, dt = pcall(parseJson,"{"..rest.."}")
    if succ then
        return dt
    else
        -- logTable(dt)
        self:logParseError(dt,"\n",rest,"\n",text)
        self:stop_for_player()
        -- log(rest)
    end
end

Invoke.functions = {}
-- Invoke.keywords = {}
---@type {[string] : FunctionDoc}
Invoke.function_docs = {}
Invoke.function_docs_by_section = {}

---@class FunctionDoc
---@field key string
---@field docs {text: string?, rest:string?, value:any?,  example:string?}[]
---@field alt_keys string[]
---@field invoke Invoke
---@field func fun()
---@field section string?
local function_metatable = {
}
function_metatable.__index = function_metatable

---@param tbl {text: string?, rest:string?, value:any?, example:string?}
function function_metatable:addDoc(tbl)
    self.docs[#self.docs+1] = tbl
    return self
end

---@param name string
---@return FunctionDoc
function function_metatable:addAlternateNames(name,...)
    for index, value in ipairs({name,...}) do
        self.alt_keys[#self.alt_keys+1] = value
        self.invoke:_registerDoc(value,self)
    end
    return self
end

---@param section string
function function_metatable:setSection(section)
    self.section = section
    if not self.invoke.function_docs_by_section[section] then
        self.invoke.function_docs_by_section[section] = {}
    end
    self.invoke.function_docs_by_section[section][#self.invoke.function_docs_by_section[section]] = self.key
    return self
end

function function_metatable:explain()
    return toJson({docs = self.docs, alternative_keys = self.alt_keys[1] and self.alt_keys})
end

function Invoke:_registerDoc(key,doc)
    if self.functions[key] then
        error("multiple assignments for the same function name: " .. tostring(key))
    end
    self.functions[key] = doc.func
    self.function_docs[key] = doc
    return doc
end

---a function
---@param key string
---@param func fun(self:Invoke,value:table,rest:string,plr:Entity):...
---@return FunctionDoc
function Invoke:register(key,func)
    return self:_registerDoc(key,
        setmetatable({invoke=self,key=key,docs={},alt_keys={},func=func},function_metatable)
    )
end
function Invoke:run(key,tbl,rest,plr)
    if self.functions[key] then
        local succ, val = pcall(self.functions[key],self,tbl,rest or "",plr)
        if succ then
            return val
        else
            self:log(val)
        end
    end
end

---runs each command in the table
---@param tbl table
---@param plr Entity
function Invoke:runTable_(tbl,plr)
    local out
    for key, value in pairs(tbl) do
        out = self:materializeBranch(key,plr,value)
    end
    return out
end


--- currently identical to :register
--- rest is the captured part: "key(.sub1.sub2)"
---@param key string
---@param func fun(self:Invoke,tbl:table,rest:string,plr:Entity):unknown?
function Invoke:registerKeyword(key,func)
    return self:register(key,func)
end


--- todo: add tags that set the result to a variable, and... 
---     could this be implemented by wrapping tbl in {Literal=<tbl>}
---     is the start.rest split done with arguments? 
---currently calls the key with value={}
---@param word string|table
function Invoke:materializeBranch(word,plr,tbl)
    if not word then return end
    if type(word) == "table" then
        return self:runTable_(word,plr or self.plr)
    end
    local _,_,start,rest = string.find(word,"^([^%.]*)%.?(.*)$")
    if self.functions[start] then
        -- log(start,rest)
        return self:run(start,tbl,rest,plr or self.plr)
    else
        return word
    end
end
Invoke.runTable = Invoke.materializeBranch


-- todo: make it so a clipboard next to a head is also read.

function Invoke:execute(data,plr)
    -- logTable(data)
    self:materializeBranch(data,plr)
end

local globalPageTag = "global"

Invoke.ephemeral_infos = {}

function Invoke:reinitialize()
    self.substitutions = {}
    self.canceledEarly = false
    if self.ephemeral_infos then
        for key, value in pairs(self.ephemeral_infos) do
            value:remove()
        end
    end
    -- self.ephemeral_infos = {}
end
function Invoke:addgsub(pattern,repl,page,rec)
    self.substitutions[#self.substitutions+1] = {pattern=pattern,repl=repl,page=page,rec=rec}
end

--- makes it so gsub doesn't affect things until unfreezegsub is called.
--- allows making multiple gsubs that would error when partially applied
function Invoke:freezegsub()
    self.frozengsub = #self.substitutions
end
function Invoke:unfreezegsub()
    self.frozengsub = nil
end
Invoke.max_substitutions = 0x400
function Invoke:substitute(text,page)
    for index, value in ipairs(self.substitutions) do
        local count
        local total_count = 0
        if ((not self.frozengsub) or self.frozengsub >= index) and ((not value.page) or value.page == page) then
            self:logSubstitution(":", value.pattern, value.repl)
            self:logSubstitution("+",text)
            repeat
                text, count = string.gsub(text,value.pattern,value.repl)
                total_count = total_count + count
                self:logSubstitution("-",text,count)
                if total_count > self.max_substitutions then
                    error("exceeded max substitution limit of " .. self.max_substitutions .. "for one line: " .. text)
                end
            until (not value.rec) or count == 0
        end
    end
    return text
end


function Invoke:logSubstitution(...)
    -- return log(...)
end

function Invoke:pageTagPresent(page,tag)
    local w = page and page[1]
    if not (w and w.checked == 0) then
        return false
    end
    local text = w.text
    local st, en, q = string.find(text,tag)
    return not not st
    
end


function Invoke:isPageActive(index)
    if self.content.type ~= "written" then return false end
    if self.canceledEarly then return false end
    if index == self.content.previously_opened_page + 1 then
        return true
    end
    local page = self.content.pages[index]
    if self:pageTagPresent(page,globalPageTag) then
        return true
    end
    return false
end

function Invoke:runPage(index)
    if not self:isPageActive(index) then
        return
    end
    local current_page = self.content.pages[index]
    if not current_page then
        return
    end
    for i, line in ipairs(current_page) do
        local text = line.text
        local checked = line.checked==1
        if not checked then
            for word in string.gmatch(text, "[^;]+") do -- ; is a line separator
                local dt = self:parse_line(self:substitute(word,index))
                if dt then
                    self:execute(dt,self.plr)
                end
                if self.canceledEarly then
                    return
                end
            end

        end
    end
end
Invoke.erroredPlayers = {}

function Invoke:stop_for_player()
    if self.plr:isLoaded() then
        Invoke.erroredPlayers[self.plr:getUUID()] = true
    end
end
function Invoke:is_stopped()
    if self.plr:isLoaded() then
        return Invoke.erroredPlayers[self.plr:getUUID()]
    else
        return true
    end
end

function Invoke:resume_for_player()
    if self.plr:isLoaded() then
        Invoke.erroredPlayers[self.plr:getUUID()] = nil
    end
end

---comment
---@param content ClipboardContent
---@param plr Entity
function Invoke:contents(content,plr)
    if not content then return end
    if content.type ~= "written" then
        self:resume_for_player()
        return
    end
    if self:is_stopped() then
        return
    end
    self:reinitialize()
    local pages = content.pages
    for i = 1, #pages do
        self:runPage(i)
        if self.canceledEarly == "page" then
            self.canceledEarly = false
        end
    end
    -- local page_index = content.previously_opened_page + 1
    -- local current_page = pages[page_index]
    -- if not current_page then
    --     -- logTable(content,4)
    --     return
    -- end
    -- for index, line in ipairs(current_page) do
    --     local text = line.text
    --     local checked = line.checked==1
    --     if not checked then
    --         local dt = self:parse_line(text)
    --         if dt then 
    --             self:execute(dt,plr)
    --         end
    --     end
    -- end

end

function Invoke:cancelEarly()
    self.canceledEarly = true
end

function Invoke:cancelPage()
    self.canceledEarly = "page"
end



function Invoke.readPlayers()
    local players = world.getPlayers()
    Invoke.updatePlayerTracked(players)
    for name, plr in pairs(players) do
        local content = Invoke.extract(plr) or Invoke.extract(plr,2)
        if content then
            pcall(Invoke.contents,Invoke.newInstance(content,plr),content,plr)
            -- Invoke:contents(content,plr)
        end
    end
end

function Invoke:log(...)
    return log(...)
end

function Invoke:logUnexpected(...)
    return log(...)
end

function Invoke:logParse(...)
    return log(...)
end

function Invoke:logParseError(...)
    return log(...)
end




if avatar:getPermissionLevel() == "MAX" then
    events.WORLD_TICK:register(Invoke.readPlayers)
end


-- events.SKULL_RENDER:register(function (delta, block, item,...)
--     -- if block then
--     --     Invoke:createInfo(block:getPos(),"okkokko's skull")
--     -- end
--     -- log(delta,block,item,...)
--     if not player:isLoaded() then return end
--     -- if Invoke.startedSneaking(player) then
--     --     -- log(infoSkull:partToWorldMatrix())
--     -- end

--     -- return true
-- end)
-- events.SKULL_RENDER:register(Invoke.readPlayers)


return Invoke