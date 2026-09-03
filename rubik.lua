
local RubiksCube = {}
RubiksCube.__index = RubiksCube

local RubiksCubePiece = {}
RubiksCubePiece.__index = RubiksCubePiece

function RubiksCubePiece:isOnSide(side)

end

function RubiksCube:facingSide(side)
    
end

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
function Permutation:__pow(num)

end

local RubiksCubeSides = {}

function RubiksCubeSides.getPosRot(index,endIndex,interpolation)
    
end

function RubiksCubeSides.rotPermutation(side,dir)
    
end



--- returns the state after a rotation.
function RubiksCube.calculateRotate(side,dir,startState)
    
end

function RubiksCube:rotateSide(side,dir)
    
end


function RubiksCube:rotateSideAnimation(side,dir,endState)
    
end


-- for synchronization, rotateSide returns a serialized state