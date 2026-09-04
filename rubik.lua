
--- could I get away with serializing the cube with raw tiles, instead of the 16 moving parts?
--- do I store position -> color or tile -> position?
--- tile -> position would be better for animating the change.
--- there are 6*9 = 54 tiles, fitting in base64 with extras.
--- yeah, for simplicity let's include the middles.
--- could 4x4 rubik's cubes be possible without fundamental changes?
--- maybe generalize for arbitrary permutations?
--- yes, maybe the state and side rotations are stored as permutations
--- Utils.table.compose 

---@class Permutation
---@field arr table
local Permutation = {}
Permutation.__index = Permutation

function Permutation.new(arr)
    return setmetatable({arr=arr},Permutation)
end

---comment
---@param other Permutation
---@return Permutation
function Permutation:__mul(other)
    return Permutation.new(Utils.table.compose(self.arr,other.arr))
end

function Permutation:inverse()
    return Permutation.new(Utils.table.inverted(self.arr))
end


---comment
---@param num integer
function Permutation:__pow(num,rest)
    
    if 1 < num then
        return self:__pow(num-1,rest and (self * rest) or self)
    elseif num < 0 then
        return self:inverse():__pow(-num,rest)
    else
        return self
    end

end

local RubiksCubeSides = {}

---comment
---@param index integer
---@return DirectionNum
---@return integer
function RubiksCubeSides.sideTileIndex(index)
    return math.floor(index / 9), index % 9
end

function RubiksCubeSides.getPosRot(index,index2,interpolation)
    if index2 and interpolation and (interpolation ~= 0) then
        local pos1, rot1 = RubiksCubeSides.getPosRot(index)
        local pos2, rot2 = RubiksCubeSides.getPosRot(index2)
        return math.lerp(pos1,pos2,interpolation), math.lerpAngle(rot1,rot2,interpolation) -- does this work?
    end
    local sideIndex, tileIndex = RubiksCubeSides.sideTileIndex(index)
    Direction.toVector(sideIndex)
    local xTile = tileIndex % 3 - 1
    local yTile = math.floor(tileIndex/3) - 1

    local projectedVec = Direction.toVector(Direction.normalX(sideIndex)) * xTile + Direction.toVector(Direction.normalY(sideIndex)) * yTile
    --- todo: use Direction.normalX to find the adjacent sides
    
    -- have the side vector, then the offset vector that is normal to that.
    -- to generate the permutations, use rotation matrices and compare.
    -- maybe have a position vector that is 1(or some other) unit extruded from the cube
    





end

function RubiksCubeSides.rotPermutation(side,dir)
    
end


local RubiksCube = {}
RubiksCube.__index = RubiksCube

local RubiksCubePiece = {}
RubiksCubePiece.__index = RubiksCubePiece

function RubiksCubePiece:isOnSide(side)

end

function RubiksCube:facingSide(side)
    
end



--- returns the state after a rotation.
function RubiksCube.calculateRotate(side,dir,startState)
    
end

function RubiksCube:rotateSide(side,dir)
    
end


function RubiksCube:rotateSideAnimation(side,dir,endState)
    
end


-- for synchronization, rotateSide returns a serialized state