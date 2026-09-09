--#region Writing

---@class Writing
---@field content unknown
local Writing = {}
Writing.__index = Writing



---should this line be ignored? by default whether there's a -- at the start.
---@param line string
function Writing:lineDisabled(line)
    return not not string.find(line,"^%s*%-%-")
end

function Writing:pageIter(index)
    local current_page = self:getPage(index)
    if not current_page then
        return Utils.nop
    end
    local i = 0
    local f = Utils.nop
    return function ()
        local w
        repeat
            w = f()
            while w == nil do
                local text, not_skipped
                repeat
                    i = i + 1
                    text, not_skipped = self:getPageLine(current_page,i)
                until not_skipped
                if not text then
                    return
                end
                f = string.gmatch(text, "[^;]+")
                w = f()
            end
        until not (w and self:lineDisabled(w))

        return w
    end
end

function Writing:pageIndices()
    return Utils.table.range(self:pageCount())
end


---@package
---@type {[string] : fun(item:ItemStack,entity:Entity):Writing?}
Writing._items = {}

function Writing.isWritingItem(item,entity)
    return Writing._items[item.id] ~= nil
end

function Writing.extract(item,entity)
    local f = Writing._items[item.id]
    if f then
        return f(item,entity)
    end
    
end
function Writing:pageTagPresent(index,tag)
    local text = self:pageIter(index)()
    if not text then return false end
    local st, en, q = string.find(text,tag)
    return not not st
    
end

--#region Clipboard

---@class Writing
local Clipboard = setmetatable({}, Writing)
Clipboard.__index = Clipboard


Writing._items["create:clipboard"] = function(item)
    local content = item.tag["create:clipboard_content"]
    if content then
        return setmetatable({content=content}, Clipboard)
    end
end


--- overrideable
function Clipboard:getPage(index)
    return type(index) ~= "number" and index or self.content.pages[index]
end


--- overrideable
---@param page unknown
---@param i integer
---@return string|nil text exists if the line exists
---@return boolean not_skipped whether this should not be skipped. is true if the line does not exist (to exit the loop)
function Clipboard:getPageLine(page,i)
    local line = page[i]
    return line and line.text, (not line) or line.checked ~= 1
end

--- overrideable
function Clipboard:pageCount()
    return #self.content.pages
end

--- overrideable
function Clipboard:selectedPageIndex()
    return self.content.previously_opened_page + 1
    
end
--- overrideable
function Clipboard:isOpen()
    return self.content.type ~= "written"
end



--#region Book

local Book = setmetatable({},Writing)
Book.__index = Book

Writing._items["minecraft:writable_book"] = function(item,entity)
    local content = item.tag["minecraft:writable_book_content"]
    -- logTable(item.tag)
    if content then
        return setmetatable({content=content,is_open = require("./HostScreen").is(entity,"BookEditScreen")}, Book)
    end
end

--- overrideable
function Book:getPage(index)
    return self.content.pages[index]
end


--- overrideable
---@param page unknown
---@param i integer
---@return string|nil text exists if the line exists
---@return boolean not_skipped whether this should not be skipped. is true if the line does not exist (to exit the loop)
function Book:getPageLine(page,i)
    if i > 1 then
        return nil, true
    else
        return page and page.raw, true
    end
end

--- overrideable
function Book:pageCount()
    return #self.content.pages
end

--- overrideable
function Book:selectedPageIndex()
    return 1
    
end
--- overrideable
function Book:isOpen()
    return self.is_open
end



--#endregion Book


-- /figura run Sleep:queue(30,FU.composed, FU.both(log,FU.compose({host.setClipboard,host},tostring)), host.getScreen, host,0)
-- /figura run Sleep:queue(30,FU.composed, FU.both(log,FU.compose({host.setClipboard,host},tostring)), host.getScreen, host,0)
-- net.minecraft.client.gui.screens.inventory.BookEditScreen

return Writing