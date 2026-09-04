local Utils = require"utils"

---@alias DirectionNum  0 | 1 | 2 | 3 | 4 | 5
---@alias DirectionName "down" | "up" | "north" | "south" | "west" | "east"
---@alias DirectionRep DirectionNum|DirectionName
---@alias Direction Vector | DirectionRep

Direction = {}

Direction.names = {
    [0] = "down",
    "up",
    "north",
    "south",
    "west",
    "east",

}

Direction.vectors = {
    [0] = vec(0, -1, 0),
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
Direction.names_to_num = {
    down = 0,
    up = 1,
    north = 2,
    south = 3,
    west = 4,
    east = 5,
}

-- local w = Direction.names_to_num["down"]


Direction.num_to_vector = { -- repeated in Direction.vectors
    [0] = vec(0, -1, 0),
    vec(0, 1, 0),
    vec(0, 0, -1),
    vec(0, 0, 1),
    vec(-1, 0, 0),
    vec(1, 0, 0)
}
Direction.vector_to_num = Utils.table.inverted(Direction.num_to_vector)


---@param dir DirectionRep
---@return Vector
function Direction.toVector(dir)
    return Direction.vectors[dir]
end

function Direction.toEulerAngles(dir)
    return Utils.math.directionToEulerAngle(Direction.toVector(dir))
end


function Direction.rotate(direction,axis,quarters)
    return vectors.rotateAroundAxis(90*(quarters or 1),Direction.toVector(direction),Direction.toVector(axis))
end


function Direction.flip(dir)
    return bit32.bxor(dir,1)
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


return Direction