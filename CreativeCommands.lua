


Ccom = {} 
Ccom.helper = {}



function Ccom.helper.vector(vector)
    if type(vector) =="number" then
        vector = vec(1,1,1) * vector
    end
    return ("%d %d %d"):format(vector:unpack())
end
function Ccom.helper.WEvector(vector)
    if type(vector) =="number" then
        vector = vec(1,1,1) * vector
    end
    return ("%d,%d,%d"):format(vector:unpack())
end

function Ccom.helper.rect(rect)
    return ("%s %s"):format(Ccom.helper.vector(rect[1]),Ccom.helper.vector(rect[2]))
end



function Ccom.helper.WErect(rect)
    return ("%s %s"):format(Ccom.helper.WEvector(rect[1]),Ccom.helper.WEvector(rect[2]))
end

function Ccom.log(...)
    -- return log(...)
end

function Ccom.sendChatCommand(...)
    Ccom.log(...)
    host:sendChatCommand(...)
    return Ccom
end

function Ccom.assemble(rect)
    -- Ccom.log("assemble",tostring(rect))
    Ccom.sendChatCommand(("sable assemble area %s"):format(Ccom.helper.rect(rect)))
end

---comment
---@param rect Rect
---@param block string
---@param mode string?
---@param second string?
function Ccom.fill(rect,block,mode,second)
    -- Ccom.log("fill",tostring(rect),block,mode,second)
    Ccom.sendChatCommand(("fill %s %s"):format(Ccom.helper.rect(rect), table.concat({block,mode,second}," ")))
end
function Ccom.fill_hollow(rect,block)
    return Ccom.fill(rect,block,"hollow")
end

function Ccom.fill_replace(rect,block,replaced)
    return Ccom.fill(rect,block,"replace",replaced)
end
function Ccom.setblock(vector,block,mode,second)
    Ccom.sendChatCommand(("setblock %s %s"):format(Ccom.helper.vector(vector), table.concat({block,mode,second}," ")))
end


function Ccom.setRect(rect)
    Ccom.rect = rect
    Ccom.sendChatCommand(("//pos %s"):format(Ccom.helper.WErect(rect)))
    return rect
end


function Ccom.generate(block,expression,flags)
    Ccom.sendChatCommand(("//g %s %s %s"):format(flags or "-r",block,expression))
end

Ccom.expressions = {}

function Ccom.expressions.manhattanDistance(pos)
    return ("abs(%d-x)+abs(%d-y)+abs(%d-z)"):format(pos:unpack())
end
function Ccom.expressions.manhattanSphere(pos,radius)
    return ("%s==%d"):format(Ccom.expressions.manhattanDistance(pos),radius)
end
function Ccom.expressions.manhattanHalfSphere(pos,radius)
    return ("(%s)*(%d<=y)"):format(Ccom.expressions.manhattanSphere(pos,radius),pos.y)
end


--- expands the rect at both edges by the vector
--- negative vectors contract
---@param vector Vector
---@return Rect
function Rect:expand(vector)
    return Rect(self[1] - vector, self[2] + vector)
end

function Rect:bottom()
    return Rect(self[1],self[2].x_z + self[1]._y_)
end

--- at the position, fills a hollow cup at the rect
---@param rect Rect
---@param block string
function Ccom.cup(rect,block)
    rect = rect:positive()
    local bottom = rect:bottom():expand(vec(-1,0,-1))
    Ccom.fill_hollow(rect,block)
    Ccom.fill_replace(bottom,"air",block)
    return rect, bottom
end

--- at the position, fills a hollow cup at the rect
---@param center Vector
---@param radius number
---@param block string
function Ccom.manhattanHalfSphere(center,radius,block)
    local rect = Ccom.setRect(Rect(0,vec(0,radius,0)):expand(vec(radius,0,radius))+center)
    Ccom.generate(block,Ccom.expressions.manhattanHalfSphere(center,radius),"-r")
    return rect
end


function Ccom.cupAssemble(rect,block)
    local rc = Ccom.cup(rect,block)
    Ccom.assemble(rc)
    return rc
end

function Ccom.stackCups(count, size,height,expansion)
    local block = host:getPickBlock()
    if not block then
        log("no block")
        return end
    local pos = block:getPos()
    local id = block:getID()
    count = count or 5
    size = size or 10
    height = height or size
    expansion = expansion or 1
    local startpos = pos
    local top = pos
    for i = 1, count do
        pos = pos + vec(0,height,0)
        local rect = Rect(0,0):expand(vec(size,0,size)) + Rect(0,vec(0,height,0)) +pos
        Ccom.cup(rect,id)
        top = rect.center.x_z + rect.pos2._y_
        Ccom.setblock(top,"air")
        Ccom.assemble(rect)
        size = size + expansion
        height = height + 1
    end

    Ccom.fill(Rect(startpos,top),"packed_ice") 
end

Ccom.color_sequence = {
    "white",
    "light_gray",
    "gray",
    "black",
    "brown",
    "red",
    "orange",
    "yellow",
    "lime",
    "green",
    "teal",
    "light_blue",
    "blue",
    "purple",
    "magenta",
    "pink"
}

function Ccom.stackPyramids(count, size, expansion,space,noassembly)
    local block = host:getPickBlock()
    if not block then
        log("no block")
        return end
    local pos = block:getPos()
    local id = block:getID()
    count = count or 5
    size = size or 10
    -- height = height or size
    expansion = expansion or 1
    local startpos = pos
    local top = pos
    for i = 1, count do
        local blk = string.gsub(id,"white",Ccom.color_sequence[(i - 1) % 16 + 1])
        pos = pos + vec(0,((space or 0) < 0) and (-space) or (size + (space or 0)),0)
        local rect = Ccom.manhattanHalfSphere(pos,size,blk)
        top = rect.center.x_z + rect.pos2._y_
        -- Ccom.setblock(top,"air")
        if not noassembly then Ccom.assemble(rect) end
        size = size + expansion
        -- height = height + 1
    end

    -- Ccom.fill(Rect(startpos,top),"packed_ice") 
end