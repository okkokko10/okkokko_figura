

---@class Writing
---@field content unknown
local Clipboard = {}
Clipboard.__index = Clipboard

---should this line be ignored? by default whether there's a -- at the start.
---@param line string
function Clipboard:lineDisabled(line)
    return not not string.find(line,"^%s*%-%-")
end

function Clipboard:getPage(index)
    return type(index) ~= "number" and index or self.content.pages[index]
end

function Clipboard:pageIter(index)
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
        until not (w and self:lineDisabled(w))

        return w
    end
end
function Clipboard:pageCount()
    return #self.content.pages
end

function Clipboard:pageIndices()
    return Utils.table.range(self:pageCount())
end


function Clipboard:selectedPageIndex()
    return self.content.previously_opened_page + 1
    
end
function Clipboard:isOpen()
    return self.content.type ~= "written"
end




function Clipboard.extract(item)
    if item.id ~= "create:clipboard" then return end
    local content = item.tag["create:clipboard_content"]
    if content then
        return setmetatable({content=content}, Clipboard)
    end
end
function Clipboard:pageTagPresent(index,tag)
    local text = self:pageIter(index)()
    if not text then return false end
    local st, en, q = string.find(text,tag)
    return not not st
    
end


local Book = setmetatable({},Clipboard)
Book.__index = Book

-- function Book:()
    
-- end

return Clipboard