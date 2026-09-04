
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
    return setmetatable(arr,Permutation)
end

---comment
---@param other Permutation
---@return Permutation
function Permutation:__mul(other)
    return Permutation.new(Utils.table.compose(self,other))
end

function Permutation:inverse()
    return Permutation.new(Utils.table.inverted(self))
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

---@alias Fin<x> integer
---@alias Range<from,to> integer

---@alias RubiksCubeTileIndex Fin<54>
---@alias RubiksCubeSideTileIndex Fin<9>

---comment
---@param index RubiksCubeTileIndex
---@return DirectionNum
---@return RubiksCubeSideTileIndex
function RubiksCubeSides.sideTileIndex(index)
    return math.floor(index / 9), index % 9
end

---comment
---@param tileIndex RubiksCubeSideTileIndex
---@return Range<-1,1>
---@return Range<-1,1>
function RubiksCubeSides.planeYX(tileIndex)
    return  math.floor(tileIndex/3) - 1, tileIndex % 3 - 1
end



function RubiksCubeSides.initialize()

    ---@type {[DirectionNum] : RubiksCubeTileIndex[] }
    RubiksCubeSides.sideIncluded = {}
    for i = 0, 5 do
        RubiksCubeSides.sideIncluded[i] = {}
    end
    RubiksCubeSides.indexCount = 6 * 9
    ---@type { [RubiksCubeTileIndex] : RubiksCubeTile}
    RubiksCubeSides.tiles = {}

    -- ---imagine a 3x3x3 cube covered with 6 3x3 planes. this maps from a point to the tile.
    -- ---@type {[Vector] : RubiksCubeTileIndex}
    -- RubiksCubeSides.points = {}

    RubiksCubeSides.packeds = {}

    for index = 0, RubiksCubeSides.indexCount - 1 do
        ---@class RubiksCubeTile
        local tile = {}
        RubiksCubeSides.tiles[index] = tile
        ---@type RubiksCubeTileIndex
        tile.index = index
        tile.side, tile.tileIndex = RubiksCubeSides.sideTileIndex(index)

        ---@type {[DirectionNum] : boolean?}
        tile.connected = {}

        local planeY, planeX = RubiksCubeSides.planeYX(tile.tileIndex)

        if planeX ~= 0 then
            local q = Direction.flip(Direction.normalX(tile.side), planeX == 1)
            table.insert(RubiksCubeSides.sideIncluded[q],index)
            tile.connected[q] = true
            ---@type DirectionNum?
            tile.adjacentX = q
        end
        if planeY ~= 0 then
            local q = Direction.flip(Direction.normalY(tile.side), planeY == 1)
            table.insert(RubiksCubeSides.sideIncluded[q],index)
            tile.connected[q] = true
            ---@type DirectionNum?
            tile.adjacentY = q
        end
        table.insert(RubiksCubeSides.sideIncluded[tile.side],index)
        tile.connected[tile.side] = true
        
        tile.projection = Direction.toVector(tile.adjacentX) + Direction.toVector(tile.adjacentY)
        tile.normal = Direction.toVector(tile.side)
        tile.position = tile.normal + tile.projection
        tile.extruded = tile.position + tile.normal

        --- the tile is described by its side, adjacentMin and adjacentMax when disregarding rotation, and they each rotate
        -- tile.adjacentMin = math.min(tile.adjacentX or Direction.null, tile.adjacentY or tile.side)
        -- tile.adjacentMax = math.max(tile.adjacentX or tile.side, tile.adjacentY or tile.side)
        
        tile.packed = Direction.packSort23(Direction.packMany(tile.side,tile.adjacentX,tile.adjacentY))
        RubiksCubeSides.packeds[tile.packed] = tile.index
        ---@type {[DirectionNum] : RubiksCubeTileIndex}
        tile.rotated = {}

    end
    for index = 0, RubiksCubeSides.indexCount - 1 do 
        local tile = RubiksCubeSides.tiles[index]
        for i = 0, 5 do
            local p = Direction.packSort23(Direction.rot(i,tile.packed))
            tile.rotated[i] = assert(RubiksCubeSides.packeds[p])
        end
    end
    return RubiksCubeSides
end


function RubiksCubeSides.initialize_permutations()
    ---@type {[DirectionNum]:Permutation}
    RubiksCubeSides.permute_whole = {}
    ---@type {[DirectionNum]:Permutation}
    RubiksCubeSides.permute_side = {}
    for side = 0, 5 do 
        RubiksCubeSides.permute_whole[side] = Permutation.new{}
        RubiksCubeSides.permute_side[side] = Permutation.new{}
    end

    for index = 0, RubiksCubeSides.indexCount - 1 do
        local t = RubiksCubeSides.tiles[index]
        for side = 0, 5 do
            RubiksCubeSides.permute_whole[side][index] = t.rotated[side]
            RubiksCubeSides.permute_side[side][index] = t.connected[side] and t.rotated[side] or t.index
        end
    end
    ---@type {[DirectionNum]:Permutation}
    RubiksCubeSides.permute_side_reverse = {}
    for side = 0, 5 do
        RubiksCubeSides.permute_side_reverse[side] =RubiksCubeSides.permute_side[side]:inverse()
    end
    
    ---@type {[DirectionNum]:Permutation}
    RubiksCubeSides.permute_whole_reverse = {}
    for side = 0, 5 do
        RubiksCubeSides.permute_whole_reverse[side] =RubiksCubeSides.permute_whole[Direction.flip(side)]
    end



    -- for side = 0, 5 do 
    --     RubiksCubeSides.permute_whole[side] = Permutation.new{}
    -- end
    return RubiksCubeSides
end

RubiksCubeSides.initialize().initialize_permutations()

local DrawLine = require("scanning.DrawLine")
---comment
---@param part ModelPart
function RubiksCubeSides.makeParts(part)
    -- local size = 16
    for index = 0, RubiksCubeSides.indexCount - 1 do
        local tile = RubiksCubeSides.tiles[index]
        
        for i = 0, 5 do
            DrawLine.line(part:newPart("" .. index .. " " .. i),
                tile.extruded*PS + tile.normal,
                RubiksCubeSides.tiles[tile.rotated[i]].extruded*PS+ tile.normal,
                {
                    width = 1/2,
                    color = Direction.colors[i],
                    opacity = 1/4,
                    seeThrough=true
                }
            )
            
            
        end
        part:newText(index)
            :setPos(tile.extruded*PS + tile.normal)
            :setText(("%s : %s"):format(tile.index,table.concat(tile.rotated,"  ")))
            :setScale(1/8)
            :setRot(Utils.math.directionToEulerAngle(tile.normal))
            :setAlignment("CENTER")
            :setSeeThrough(true)

    end

    part:newItem("center"):setItem("glass")


end
require("utils")
local RubikBase = Positioning.parts.World:newPart("RubikBase"):setPos(PS*1,PS*1,PS*-3)

RubiksCubeSides.makeParts(RubikBase)


Utils.ID.field.RubikBase = RubikBase

-- DrawLine.test(RubikBase)

require("redo.Grab").addSelectableGenerate("RubikBase")




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