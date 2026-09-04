local Utils = require"utils"

----@alias DirectionNum  0 | 1 | 2 | 3 | 4 | 5

---@alias DirectionName "down" | "up" | "north" | "south" | "west" | "east"
---@alias DirectionRep DirectionNum|DirectionName
---@alias Direction Vector | DirectionRep

Direction = {}

Direction.names = {
    [0] =
    "down",
    "up",
    "north",
    "south",
    "west",
    "east",

}

Direction.vectors = {
    [0] =
    vec(0, -1, 0),
    vec(0, 1, 0),
    vec(0, 0, -1),
    vec(0, 0, 1),
    vec(-1, 0, 0),
    vec(1, 0, 0),
    down = vec(0, -1, 0),
    up = vec(0, 1, 0),
    north = vec(0, 0, -1),
    south = vec(0, 0, 1),
    west = vec(-1, 0, 0),
    east = vec(1, 0, 0),
}


-- Direction.names_to_num = Utils.table.inverted(Direction.names)

---@enum DirectionNum
Direction.names_to_num = {
    down = 0,   -- 00 0
    up = 1,     -- 00 1
    north = 2,  -- 01 0
    south = 3,  -- 01 1
    west = 4,   -- 10 0
    east = 5,   -- 10 1
}


Direction.colors = {
    [0] =
    "#FF0000",
    "#00FFFF",
    "#00FF00",
    "#FF00FF",
    "#0000FF",
    "#FFFF00"
}


Direction.num_to_vector = { -- repeated in Direction.vectors
    [0] =
    vec(0, -1, 0),  -- 00 0
    vec(0, 1, 0),   -- 00 1
    vec(0, 0, -1),  -- 01 0
    vec(0, 0, 1),   -- 01 1
    vec(-1, 0, 0),  -- 10 0
    vec(1, 0, 0)    -- 10 1
}
Direction.vector_to_num = Utils.table.inverted(Direction.num_to_vector)

--- returns the zero vector if false.
---@param dir DirectionRep|false
---@return Vector
function Direction.toVector(dir)
    return Direction.vectors[dir] or vec(0,0,0)
end

function Direction.toEulerAngles(dir)
    return Utils.math.directionToEulerAngle(Direction.toVector(dir))
end


-- function Direction.rotate(axis,direction,quarters)
--     return vectors.rotateAroundAxis(90*(quarters or 1),Direction.toVector(direction),Direction.toVector(axis))
-- end

--- cross product: ...x y z x y z...  
---where the loop has ...c a b c...,   
---   a × b = c,  
---   b × a = -c ("going against the grain" negates it)  
---@param a DirectionNum
---@param b DirectionNum
---@return DirectionNum|false
function Direction.cross(a,b)
    -- 1: no flip, 2: flip, 0: same
    local d = (bit32.rshift(b,1) - bit32.rshift(a,1)) % 3
    if d == 0 then return false end
    return bit32.bxor(a,b,6,d%2) -- 110
end


---are the directions on the same axis? returns false if either is false
---@param a DirectionNum|false
---@param b DirectionNum|false
---@return boolean|false
function Direction.sameAxis(a,b)
    return a and b and bit32.bxor(a,b) <= 1
end

local NullDirection = 7 -- 6 also is a null direction?
Direction.null = NullDirection

function Direction.isNull(direction)
    return (not direction) or direction == NullDirection
end


---@overload fun(axis: DirectionNum, direction: DirectionNum,quarters: integer?): DirectionNum
---@overload fun(axis: DirectionNum, direction: false, quarters: integer?): false
---@overload fun(axis: DirectionNum, direction: DirectionNumPacked,quarters: integer?): DirectionNumPacked
---comment
---@param axis DirectionNum
---@param direction DirectionNum
---@param quarters integer?
---@return DirectionNum
function Direction.rot(axis,direction,quarters)
    if Direction.isNull(direction) then return false end
    local v,c = Direction.unpack(direction)
    if c then
        local w = Direction.rot(axis,c,quarters)
        ---@cast w DirectionNumPacked
        return Direction.pack(Direction.rot(axis,v,quarters),w)
    end

    if quarters then
        local modu = quarters % 4
        if modu == 0 then
            return direction
        elseif modu == 2 then
            return Direction.flip(direction,Direction.sameAxis(axis,direction))
        elseif modu == 3 then
            return Direction.cross(Direction.flip(axis),direction) or direction
        end
    end
    return Direction.cross(axis,direction) or direction
end

---@class DirectionNumPacked: integer

--- will pack at most 8 directions into a stack. false will be packed as 6.
--- if a function accepts DirectionNumPacked, it will be vectorized
---@param value DirectionNum|false
---@param cons DirectionNumPacked|DirectionNum?
---@return DirectionNumPacked
function Direction.pack(value,cons)
    return bit32.bor(value or NullDirection, 8, bit32.lshift(cons or NullDirection,4))
end

---pops the stack
---@param packed DirectionNumPacked
---@return DirectionNum|false
---@return DirectionNumPacked?
function Direction.unpack(packed)
    if bit32.btest(packed,8) then
        local th = bit32.band(packed,7)
        if Direction.isNull(th) then
            return false, bit32.rshift(packed,4)
        end
        return th, bit32.rshift(packed,4)
    else
        if Direction.isNull(packed) then
            return false
        end
        return packed
    end
end
function Direction.packMany(x,...)
    if select("#",...) == 0 then
        return x or NullDirection
    else
        return Direction.pack(x,Direction.packMany(...))
    end
end
function Direction.unpackMany(packed)
    local v,c = Direction.unpack(packed)
    if c then
        return v, Direction.unpackMany(c)
    else
        return v
    end
end
---sorts the second and third, for cases where their order does not matter. 
---@param packed DirectionNumPacked
---@return DirectionNumPacked
function Direction.packSort23(packed)
    local a,b,c = Direction.unpackMany(packed)
    if (c or Direction.null) < (b or Direction.null) then
        b,c = c,b
    end
    return Direction.packMany(a,b,c)
end


---flips the number, or doesn't if disable is flagged
---@param dir DirectionNum
---@param disable boolean?
---@return DirectionNum
function Direction.flip(dir,disable)
    return dir and bit32.bxor(dir,disable and 0 or 1)
end


---@param dir DirectionNum
---@return DirectionNum
function Direction.normalX(dir)
    return (dir + 2) % 6
end

--- is also the normalX of normalX
---@param dir DirectionNum
---@return DirectionNum
function Direction.normalY(dir)
    return (dir + 4) % 6
end

--- normalX o normalX = normalY
--- normal_ commutes with flip
--- looks like normalX × normalY = original, so they should orient the same.



---@package
function Direction._test_cross()
    for i = 0, 5 do
        for j = 0, 5 do
            local k = Direction.cross(i,j)
            local vi = Direction.toVector(i)
            local vj = Direction.toVector(j)
            local vk = Direction.toVector(k)
            local vv = vi:crossed(vj)
            -- print(i,j,k,vi,vj,vk,vv)
            assert(vv == vk)
            
        end
    end
end
if host:isHost() then Direction._test_cross() end


--- hm, could it be better that 6 is another word for 0, and 7 is false? that way there would be a nonzero way to write any value


---@package
function Direction._test_pack_rot()
    for h = 0,5 do
        ---@type integer|false
        for i = 0, 6 do
            i = i ~= 6 and i or false
            local ri = Direction.rot(h,i)

            ---@type integer|false
            for j = 0, 6 do
                j = j ~= 6 and j or false
                local packedR = Direction.pack(Direction.rot(h,j),ri)
                local packedJ = Direction.pack(j,i)
                ---@type integer|false
                for k = 0, 6 do
                    k = k ~= 6 and k or false
                    local packed = Direction.pack(k,packedJ)
                    local ro = Direction.rot(h,packed)
                    local pro = Direction.pack(Direction.rot(h,k),packedR)
                    -- print(h,i,j,k,ro,pro)
                    assert(ro == pro)

                end
            end
        end
    end
end
if host:isHost() then Direction._test_pack_rot() end




return Direction