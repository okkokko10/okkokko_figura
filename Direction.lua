local Utils = require"utils"


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



---@param dir string|integer
---@return Vector
function Direction.toVector(dir)
    return Direction.vectors[dir]
end

function Direction.toEulerAngles(dir)
    return Utils.math.directionToEulerAngle(Direction.toVector(dir))
end


return Direction