



--- plans:
--- function to create a KineticPath object
--- method that creates a visual for the KineticPath
--- method to discard that visual.










---not exact. relies on a (possibly unfounded) assumption that sublevels will not be over 1000 blocks in diameter
--- not used for important logic here
---returns true if both are in the world
---@param pos1 Vector
---@param pos2 Vector
---@return boolean
function Utils.Sublevel.areInSameSublevel(pos1,pos2)
    if (Utils.Sublevel.isInSublevel(pos1) or Utils.Sublevel.isInSublevel(pos2)) then
        return (pos1-pos2):lengthSquared() < 1000*1000
    else
        return true
    end
  
end

---returns pos1-pos2 if they are in the same sublevel, otherwise returns nil
---@param pos1 Vector
---@param pos2 Vector
---@return Vector|nil
function Utils.Sublevel.difference(pos1,pos2)
    return Utils.Sublevel.areInSameSublevel(pos1,pos2) and (pos1-pos2) or nil

end


---@alias KineticPathStatus "exceeds_length"|"unloaded"|"not_block_entity"|"no_network"|"root_reached"

---@class KineticPath
---@field start_pos Vector
---@field path? KineticPathNode[]
---@field length number
---@field end_pos Vector
---@field penultimate_pos Vector?
---@field status KineticPathStatus?
---@field part ModelPart?
---@field path_parts ModelPart[]?
local KineticPath = {
  pathLength = 32,
--   -@type KineticPathNode[]
--   sourcePath = {}, -- {x,y,z,type}
}
KineticPath.__index = KineticPath





--- todo: maybe abstract it so you can track more kinds of networks with it.
---@param pos Vector
---@param pathLength number?
---@param noList boolean? if true, discards the intermediate path. todo: still saves the second-to-last to determine if the unloaded endpoint is in a different (sub)level
---@return KineticPathNode[]
---@return number length
---@return Vector endpoint
---@return Vector? penultimate_point
---@return KineticPathStatus status 
function KineticPath:make(pos,pathLength,noList)
    pathLength = pathLength or KineticPath.pathLength
    ---@type KineticPathNode[]
    local path = {}
    local status = "exceeds_length"
    local i1
    local prevPos
    for i = 1, pathLength do
      i1 = i
      if not noList then
        path[i] = {pos=pos}
      end
      local block = world.getBlockState(pos)
      ---@type {Network: {Id:number,Stress:number,Capacity:number,Size:number}?, Speed:number, Source:{[1]:number,[2]:number,[3]:number}? }?
      local blockData = block:getEntityData()
      if not blockData then
        -- either not loaded, or something weirder (or just the first block. append "_start" to the status if i==1. or return the index).
        -- todo: differentiate between being unloaded in the same level and in different levels
        if block.id == "minecraft:void_air" then -- void_air exists in unloaded chunks and beyond the build height limits. so technically this branch could also occur when a source is somehow above the build height limit.
          -- normal if on the ground, weird if the last vertex is on a sublevel.
          -- todo: report somewhere on whether the last connection is across (sub)levels.
          status = "unloaded"
        else
          -- it would be strange if this happened outside of i==1. a kinetic source that isn't a block entity.
          status = "not_block_entity"
        end
        break
      end
      local network = blockData.Network
      -- hm, technically this check doesn't have to be required, and if omitted could track other relationships where "Source" points toward a root. 
      if not (network and network.Stress) then -- there exist nbt components titled "Network" other than kinetic networks, such as big radars data networks
        --- block isn't in a kinetic network.
        --- happens if it isn't an active kinetic block.
        --- it would be odd if this happened outside i==1
        status = "no_network"
        break
      end
      if not noList then
        path[i].network = network
      end
      local speed = blockData.Speed -- currently unused, but could be displayed.
      local source = blockData.Source -- the position of the "parent" vertex.
      if not source then
        -- a kinetic network vertex that does not have a source is a root.
        -- although I wonder, would it be possible for a network to have multiple roots?
        -- todo maybe: check whether the network id depends on the root position, making the root unique.
        status = "root_reached"
        break
      end
      prevPos = pos
      local source_vec = vec(table.unpack(source))
      pos = source_vec
    end
    

    return path,i1,pos,prevPos,status
end


function KineticPath.create(pos,pathLength,noList)
    local out = setmetatable({start_pos = pos},KineticPath)
    return out
end
function KineticPath:extend(pathLength,noList)
    self.path, self.length, self.end_pos, self.penultimate_pos, self.status = KineticPath:make(self.start_pos,pathLength,noList)
end



---comment
---@param pos Vector
---@return Vector
---@return Vector
function Utils.Sublevel.getSublevelOriginOffset(pos)
    return pos,vec(0,0,0)
end

-- {20481028, 126, 20560907}
-- host:setClipboard (tostring( KineticsPath .getFirstPos() ))
-- host:setClipboard (string.format("%X, %X, %X",(KineticsPath .getFirstPos():unpack() ) ) )
-- host:setClipboard (string.format("%X, %X, %X", 20481028, 126, 20560907 ) )
-- 1388404, 7E, 139BC0B


---moves part to be a child of a child of `grandparent or models` that tracks the position of a sublevel.
---if part is string|nil, creates a new part named that or a generated name.
---@param pos Vector
---@param part ModelPart|string|nil
---@param grandparent ModelPart?
---@return ModelPart
function Utils.Sublevel.moveToSublevelPosition(pos,part,grandparent)
    grandparent = grandparent or models
    local slOrigin, slOffset = Utils.Sublevel.getSublevelOriginOffset(pos)
    local sublevelID = "sl"..tostring(slOrigin)
    if not grandparent[sublevelID] then
        Positioning.make.coordinateFollower(pos,sublevelID,grandparent)
    end
    if type(part) == "ModelPart" then
        part:moveTo(grandparent[sublevelID])
    else
        
        part = grandparent[sublevelID]:newPart((type(part) == "string") and part or tostring(slOffset))
    end
    part:setPos(slOffset*PS)
    return part
end



---@param node_data KineticPathNode
---@param i number
---@param prev_difference Vector|nil|false -- Vector: relative position of previous path node. false: previous path node in different sublevel. nil: start of list
---@param next_difference Vector|nil|false -- Vector: relative position of next path node. false: next path node in different sublevel. nil: end of list
function KineticPath:make_text(node_data,i,prev_difference,next_difference)
    return
end




local prett = {
    {"index","(%i)", condition = ""},
    {"Id","Kinetic Network %i", condition = "change"},
    {"Stress Capacity","%i/%i SU used", condition = "change"},
    {"Size","size: %i", condition = "change"},
    {"","root",condition = "isEnd & status=root_reached"},
    {"status","status: %s",condition = "isEnd -status=root_reached -isStart"},
    {"status"}


}

function KineticPath.pretty(network,oldNetwork,repeats)
  oldNetwork = oldNetwork or {}
  if network then
    return
      ((network.Id == oldNetwork.Id and (not repeats))
        and "" 
        or ("network id: " .. (network.Id or "NONE") .. "\n"))..
      ((network.Stress == oldNetwork.Stress and network.Capacity == oldNetwork.Capacity and (not repeats)) 
        and "" 
        or ((network.Stress or "") .. "/" .. (network.Capacity or "") .. "\n"))..
      ((network.Size == oldNetwork.Size and (not repeats))
        and "" 
        or ("size: " .. (network.Size or "???") .. "\n"))
  end
  return "()\n"
end




---overrideable.
---@param path_part ModelPart
---@param node_data KineticPathNode
---@param i number
---@param prev_difference Vector|nil|false -- Vector: relative position of previous path node. false: previous path node in different sublevel. nil: start of list
---@param next_difference Vector|nil|false -- Vector: relative position of next path node. false: next path node in different sublevel. nil: end of list
---@param prev_data KineticPathNode? -- for comparing differences to previous. doesn't exist if first.
function KineticPath:init_pathPart(path_part,node_data,i,prev_difference,next_difference,prev_data)
    local text = path_part:newPart("text","BILLBOARD"):newText("text")
        :setLight(15,15)
        :setWidth(16*4*3)
        :setScale(1/4)
        :setOpacity(0.5)
    if host:isHost() then
        text:setSeeThrough(true)
    end
    
end


function KineticPath:pre_init_pathPart(i)
    local node = self.path[i]
    if not node then
        error("somehow pre-initializing without having a path. i = " .. i)
        return
    end
    local prevNode = self.path[i-1]
    local nextNode = self.path[i+1]
    local main = Utils.Sublevel.moveToSublevelPosition(node.pos,nil,self.part)
    self.path_parts[i] = main
    
    local prev_difference = prevNode and (Utils.Sublevel.difference(prevNode.pos, node.pos) or false)
    local next_difference = nextNode and (Utils.Sublevel.difference(nextNode.pos, node.pos) or false)

    self:init_pathPart(main,node,i,prev_difference,next_difference)
    
end


---creates a model that displays this.
---@param rootPart ModelPart
---@param name string?
function KineticPath:createVisual(rootPart,name)
    self.part = rootPart:newPart(name or ("KineticPath"..tostring(self.start_pos)),"World")
    self.path_parts = {}
    for i, node in ipairs(self.path or {}) do
        self:pre_init_pathPart(i)
    end
end
