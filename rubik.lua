
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
---@param out Permutation? -- table
---@return Permutation
function Permutation:__mul(other,out)
    return Permutation.new(Utils.table.compose(self,other,out))
end

local mode_k = {__mode='k'}
local cached_funcs =  setmetatable({},mode_k)
local function memoize(f,x)
    local cf = cached_funcs[f]
    if not cf then
        cf = setmetatable({},mode_k)
        cached_funcs[f] = cf
    end
    local o = cf[x]
    if o then return o end
    o = f(x)
    cf[x] = o
    return o
end
local function memoize_involution(f,x)
    local cf = cached_funcs[f]
    if not cf then
        cf = setmetatable({},mode_k)
        cached_funcs[f] = cf
    end
    local o = cf[x]
    if o then return o end
    o = f(x)
    cf[x] = o
    cf[o] = x
    return o
end
local function memoize_assign(f,x,y)
    local cf = cached_funcs[f]
    if not cf then
        cf = setmetatable({},mode_k)
        cached_funcs[f] = cf
    end
    cf[x] = f(x)
end

function Permutation:_inverse()
    return Permutation.new(Utils.table.inverted(self))
end

function Permutation:inverse()
    return memoize_involution(Permutation._inverse,self)
end

function Permutation:_square()
    return self*self
end

function Permutation:square()
    return memoize(Permutation._square,self)
end

function Permutation:__eq(other)
    return Utils.table.equals(self,other)
end

--- if sq is a table and not a permutation, it is assigned the square (as shortcut to initialize it)
function Permutation:assign_square(sq)
    if type(sq) == "table" and not getmetatable(sq) then
        self:__mul(self,sq) -- converts sq into the square
        memoize_assign(Permutation._square,self,sq)
        return
    end
    local nsq = self:_square()
    assert(nsq == sq)
    memoize_assign(Permutation._square,self,sq)
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
    -- for side = 0, 5 do 
    --     RubiksCubeSides.permute_whole[side] = Permutation.new{}
    --     RubiksCubeSides.permute_side[side] = Permutation.new{}
    -- end
    for side = 0, 5 do
        local p = {}
        for index = 0, RubiksCubeSides.indexCount - 1 do
            local t = RubiksCubeSides.tiles[index]
            p[index] = t.connected[side] and t.rotated[side] or t.index
        end
        RubiksCubeSides.permute_side[side] = Permutation.new(p)
    end
    --- this way 
    for side = 0, 4, 2 do
        local p = {}
        for index = 0, RubiksCubeSides.indexCount - 1 do
            local t = RubiksCubeSides.tiles[index]
            p[index] = t.rotated[side]
        end
        RubiksCubeSides.permute_whole[side] = Permutation.new(p)
        RubiksCubeSides.permute_whole[Direction.flip(side)] = RubiksCubeSides.permute_whole[side]:inverse()
    end
    -- for index = 0, RubiksCubeSides.indexCount - 1 do
    --     local t = RubiksCubeSides.tiles[index]
    --     for side = 0, 5 do
    --         RubiksCubeSides.permute_side[side][index] = t.connected[side] and t.rotated[side] or t.index
    --     end
    --     for side = 0, 4, 2 do
    --         RubiksCubeSides.permute_whole[side][index] = t.rotated[side]
    --     end
    -- end
    -- for side = 1, 5, 2 do
    --     RubiksCubeSides.permute_whole[side] = RubiksCubeSides.permute_whole[Direction.flip(side)]:inverse()
    -- end


    
    
    -- ---@type {[DirectionNum]:Permutation}
    -- RubiksCubeSides.permute_wide = {}
    -- for side = 0, 5 do

    -- end
    

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

    ---@type {[DirectionNum]:Permutation}
    RubiksCubeSides.permute_side_twice = {}
    for side = 0, 5 do
        RubiksCubeSides.permute_side_twice[side] = RubiksCubeSides.permute_side[side]:square()
    end
    -- ---@type Permutation
    -- RubiksCubeSides.permute_whole_twice = {} -- RubiksCubeSides.permute_whole[1]:square()
    -- for side = 0, 5 do
    --     RubiksCubeSides.permute_whole[side]:assign_square(RubiksCubeSides.permute_whole_twice)
    -- end

    



    -- for side = 0, 5 do 
    --     RubiksCubeSides.permute_whole[side] = Permutation.new{}
    -- end
    return RubiksCubeSides
end

RubiksCubeSides.initialize().initialize_permutations()



local Direction = require"Direction"
RubiksCubeSides.SingmasterDirection = {
    U = Direction.names_to_num.up,
    D = Direction.names_to_num.down,
    R = Direction.names_to_num.east,
    L = Direction.names_to_num.west,
    F = Direction.names_to_num.south,
    B = Direction.names_to_num.north,
}

--- U, U' 
RubiksCubeSides.Singmaster = Utils.table.remap(
    RubiksCubeSides.SingmasterDirection,
    function (v, k)
        return RubiksCubeSides.permute_side[v],k
    end,
    Utils.table.remap(
    RubiksCubeSides.SingmasterDirection,
    function (v, k)
        return RubiksCubeSides.permute_side_reverse[v],k.."'"
    end
)
)

-- RubiksCubeSides.Singmaster2 = Utils.table.remap(
--     RubiksCubeSides.SingmasterDirection,
--     function (v, k)
--         return Direction.packMany(v,v),k
--     end,
--     Utils.table.remap(
--     RubiksCubeSides.SingmasterDirection,
--     function (v, k)
--         return Direction.packMany(v,Direction.flip(v)),k.."'"
--     end
-- )
-- )

---@param s string
function RubiksCubeSides.fromSingmaster(s)
    local a,b = string.match(s,"([UDRLFBxyz])(['2w]?)")
    
    
end


function RubiksCubeSides.fromString(str)
    
    
end

---draws lines connecting permutations.
---@param part ModelPart
function RubiksCubeSides.drawPermutationDebug(part)
    local DrawLine = require("scanning.DrawLine")
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
            :setText(
                ("%s : %s"):format(tile.index,
                toJson(
                Utils.table.flatmap(
                tile.rotated,
                function (x,i)
                    return {{
                        text = tostring(x),
                        color = Direction.colors[i]
                    },"  "}
                end)
                
                )
            )
            )
            :setScale(1/8)
            :setRot(Utils.math.directionToEulerAngle(tile.normal))
            :setAlignment("CENTER")
            :setSeeThrough(true)

    end

    part:newItem("center"):setItem("glass")


end



function RubiksCubeSides.getPosRot(index,index2,interpolation)
    if index2 and interpolation and (interpolation ~= 0) then
        local pos1, rot1 = RubiksCubeSides.getPosRot(index)
        local pos2, rot2 = RubiksCubeSides.getPosRot(index2)
        return math.lerp(pos1,pos2,interpolation), math.lerpAngle(rot1,rot2,interpolation) -- does this work?
    end

    local tile = RubiksCubeSides.tiles[index]
    
    
    return tile.position, Utils.math.directionToEulerAngle(tile.normal)
    
    
    --- todo: use Direction.normalX to find the adjacent sides
    
    -- have the side vector, then the offset vector that is normal to that.
    -- to generate the permutations, use rotation matrices and compare.
    -- maybe have a position vector that is 1(or some other) unit extruded from the cube
end

function RubiksCubeSides.rotPermutation(side,dir)
    
end


---@class RubiksCube
local RubiksCube = {}
RubiksCube.__index = RubiksCube

local RubiksCubePiece = {}
RubiksCubePiece.__index = RubiksCubePiece

function RubiksCube.new(part)
    assert(type(part)== "ModelPart")
    local perm = {}
    local parts = {}
    for i = 0, RubiksCubeSides.indexCount - 1 do
        perm[i] = i
        local tile = RubiksCubeSides.tiles[i]
        local ipart = part:newPart(i)
        parts[i] = ipart
        local scale = 2
        -- ▒ ▓ █
        local text = ('[{"text"="%s", color="%s"}]'):format(("▓"),Direction.colors[tile.side])
        ipart:newText("text")
        :setText(text)
        :setPos(vec(4,4,-4)*scale)
        :setScale(scale)
        ipart:newText("text3")
        :setText("█")
        :setPos(vec(4,4,-3)*scale)
        :setScale(scale)
        ipart:newText("text2")
        :setText(text)
        :setPos(vec(4,-4,-4)*scale)
        :setRot(180,0,0)
        :setScale(scale)
    end
    ---@class RubiksCube
    local out = {perm = Permutation.new(perm),
        oldPerm = perm,
        parts = parts,
        part = part,
        timestep = 0
        }
    

    -- events.WORLD_TICK:register(function ()
    --     out:update(0.05)
    --     out:updateParts()
    --     out:random()

    -- end)
    part.preRender = function ()
        out:update(0.05)
        out:updateParts()
        out:random()

    end

    return setmetatable(out,RubiksCube)
end


function RubiksCube:getTileOrientation(index)
    return RubiksCubeSides.getPosRot(self.perm[index],self.oldPerm[index],self.timestep)
end

function RubiksCube:rotate(side,flip)
    self.oldPerm = self.perm
    self.perm = self.perm * (flip and RubiksCubeSides.permute_side_reverse or RubiksCubeSides.permute_side)[side]
    self.timestep = 1
    
end

function RubiksCube:updateParts()
    for index = 0, RubiksCubeSides.indexCount - 1 do 
        local p = self.parts[index]
        local pos, rot = self:getTileOrientation(index)
        p:setPos(pos*PS):setRot(rot)
    end
end

function RubiksCube:update(time)
    self.timestep = math.max(0,self.timestep - (time or 0.01))
end

function RubiksCube:random()
    if self.timestep == 0 then
        local side = math.random(0,5)
        local flip = math.random(2)==1
        self:rotate(side,flip)

    end
end

--- returns the state after a rotation.
-- function RubiksCube.calculateRotate(side,dir,startState)
    
-- end

function RubiksCube:rotateSide(side,dir)
    
end


function RubiksCube:rotateSideAnimation(side,dir,endState)
    
end


require("utils")
local RubikBase = Positioning.parts.World:newPart("RubikBase"):setPos(PS*1,PS*1,PS*-3)

RubiksCubeSides.drawPermutationDebug(RubikBase)


Utils.ID.field.RubikBase = RubikBase

require"invoke.AltRendering"


Utils.ID.field.SkullStabilized = Positioning.make.absoluteRot("rubikR",Utils.ID.field.Skull:newPart("Rubik1"):setPos(0,0,-PS*7))

Utils.ID.field.Rubik =Utils.ID.field.SkullStabilized:newPart("Rubik"):setLight(8):setRot(45,0,35.264):setScale(1/3)
Utils.ID.field.Rubik:newItem("center"):setItem("target")

-- DrawLine.test(RubikBase)

require("redo.Grab").addSelectableGenerate("RubikBase")
require("redo.Grab").addSelectableGenerate("Rubik")

TheCube = RubiksCube.new(Utils.ID.field.Rubik)

-- for synchronization, rotateSide returns a serialized state