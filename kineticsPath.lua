-- Auto generated script file --


require "utils"

-- vec(20534276, 129, 20640776)
function pings.pingSublevel(pos)
  return Utils.Sublevel.sableSublevelToWorld(pos)
  
end


KineticsPath = {
  pathLength = 32, 
  ---@type KineticPathNode[]
  sourcePath = {}, -- {x,y,z,type}
}


---@return vec3|nil
function KineticsPath.getFirstPos()
  return (KineticsPath.sourcePath[1] or {}).pos
end

---@return any|nil
---@return vec3|nil
function KineticsPath.getFirstBlock()
  local pos = KineticsPath.getFirstPos()
  return pos and world.getBlockState(pos), pos
end



--entity init event, used for when the avatar entity is loaded for the first time
function events.entity_init()
  -- log("init")
  --player functions goes here

  local pathRoot = models:newPart("pathRoot","World")
  for i = 1, KineticsPath.pathLength do
    -- kineticsPath.modelPath[i] = {} 
    local main = models.pathRoot:newPart(i):setVisible(false)
    
    models.pathRoot[i]
      :newPart("block")
      :newPart("pointing")
      :newItem("glass")
        :setItem("light_blue_stained_glass")
        :setPos(vec(0,0,8))
        :setLight(15,15)
        :setScale(.5,.5,1)
    local text = main:newPart("text","BILLBOARD"):newText("text")
      :setLight(15,15)
      :setText("NONE")
      :setWidth(16*4*3)
      :setScale(1/4)
      :setOpacity(0.5)
    if host:isHost() then
      text:setSeeThrough(true)
    end
  end
  models.pathRoot
    :newPart("last"):setVisible(false)
    :newPart("rot_part")
    :newItem("block")
      :setItem("blue_stained_glass")
      :setLight(15,15)


end

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


-- todo: option to force camera to face toward path vertices, going through them.
-- also, report both world and plot positions of a faraway connection.

-- random thought: you can see the sublevel uuid using a swivel bearing?


----@param path KineticPathNode[]?

---

--- todo: maybe abstract it so you can track more kinds of networks with it.
---@param pos vec3
---@param pathLength number?
---@param noList boolean? if true, discards the intermediate path. todo: still saves the second-to-last to determine if the unloaded endpoint is in a different (sub)level
---@return KineticPathNode[]
---@return number length
---@return Vector endpoint
---@return Vector? penultimate_point
---@return "exceeds_length"|"unloaded"|"not_block_entity"|"no_network"|"root_reached" status 
function KineticsPath.make(pos,pathLength,noList)
    pathLength = pathLength or KineticsPath.pathLength
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

---@alias vec3 Vector

---@class Vector
---@field x number
---@field y number
---@field z number


---@class KineticPathNode
---@field pos vec3
---@field network? {Id:number,Stress:number,Capacity:number,Size:number}




function KineticsPath.pretty(network,oldNetwork,repeats)
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


-- should be run when the path is updated.
function KineticsPath.changeRender()

  
  for i, value in ipairs(KineticsPath.sourcePath) do
    

    local isLast = i == #KineticsPath.sourcePath
    local isOrigin = isLast and (i < KineticsPath.pathLength)

    local nextPos = KineticsPath.sourcePath[i+1] and KineticsPath.sourcePath[i+1].pos
    local localDirection = nextPos and (nextPos - KineticsPath.sourcePath[i].pos) or (vec(0,0,0))
    local angle = Utils.math.directionToEulerAngle(-localDirection)
    
    
    local l1distance = math.abs(localDirection.x)+math.abs(localDirection.y)+math.abs(localDirection.z)
    local distance = localDirection:length()
    local nextElsewhere = distance > 1000



    local netId =(value.network and value.network.Id or 0)
    local colo = vectors.intToRGB(((netId % 0x1001000) * (2654435761 % 0x1000000)))* 0.9


    models.pathRoot[i]:setVisible(true)

    models.pathRoot[i].text:getTask("text")
    :setText(Utils.string.stripWhitespace(
      (i == 1 and (not host:isHost()) and "okkokko's shared debug\n" or "") ..
      ((netId == 0) and "" or ("(" .. i .. ")\n"..
      (KineticsPath.pretty(value.network,(KineticsPath.sourcePath[i-1] or {}).network) or "") .. 
      (l1distance == 1 and "" or ((isLast and (isOrigin and "origin" or "") or ("->" .. (l1distance) .. (nextElsewhere and ("\n(" .. nextPos.x .. " " .. nextPos.y .. " " .. nextPos.z .. ")") or ""))) .. "\n")) ))
      .. (i == 1 and (((not (GIZMO or {}).noDirectNBT) and KineticsPath.firstNBT or "") .. "\n") or "")
    ))
    :setBackground(true):setBackgroundColor(colo)

    
    models.pathRoot[i].block.pointing:setRot(angle)
    
    if nextElsewhere then
      models.pathRoot[i].block.pointing:setScale(1,1,1)
    else
      models.pathRoot[i].block.pointing:setScale(1,1,distance)
    end

    
    models.pathRoot[i].block:setVisible(not isLast)
    if isLast then
      models.pathRoot.last:setVisible(isOrigin)
    end

  end
end

-- just updates the positions
-- todo: system to have just one part per sublevel that changes position each tick, that is a parent to the rest.
function KineticsPath.updateRender()
  if #KineticsPath.sourcePath < 1 then
    return
  end

  -- local rot = player:isLoaded() and player:getRot() or vec(0,0)
  -- local sneaking = false


  local cameraPos = client.getCameraPos()


  -- local worldPath = {}
  -- for i = 1, #kineticsPath.sourcePath do
  --   worldPath[i] = sableSublevelToWorld(kineticsPath.sourcePath[i].pos + 1/2)
  -- end
  
  local levelRot --= levelRotationMatrix(kineticsPath.sourcePath[1].pos)
  local nextElsewhere = true
  for i = 1, #KineticsPath.sourcePath do
    if nextElsewhere then
      levelRot = Utils.Sublevel.sublevelRotationMatrix(KineticsPath.sourcePath[i].pos)
      nextElsewhere = false
    end

    local isLast = i == #KineticsPath.sourcePath
    local isOrigin = isLast and (i < KineticsPath.pathLength)

    local sv = Utils.Sublevel.sableSublevelToWorld(KineticsPath.sourcePath[i].pos + 1/2)
    local nextPos = KineticsPath.sourcePath[i+1] and KineticsPath.sourcePath[i+1].pos
    local localDirection = nextPos and (nextPos - KineticsPath.sourcePath[i].pos) or (vec(0,0,0))
    
    
    local distance = localDirection:length()
    nextElsewhere = distance > 1000

    models.pathRoot[i]:setPos(sv*16)
    models.pathRoot[i].text:getTask("text")
    :setSeeThrough( (cameraPos - sv):length() < 10 or host:isHost())

    

    models.pathRoot[i].block:setMatrix(levelRot)
    

    if isLast and isOrigin then
      models.pathRoot.last.rot_part:setMatrix(levelRot)
      models.pathRoot.last:setPos(sv*16)
    end
  end
end




function KineticsPath.setPath(path, oldSize)
  if #path < (oldSize or #KineticsPath.sourcePath) then
    for i = #path+1, (oldSize or #KineticsPath.sourcePath) do
      models.pathRoot[i]:setVisible(false)
    end
  end
  models.pathRoot.last:setVisible(false)
  KineticsPath.sourcePath = path
end

local pingBuffer = {}


local function localKineticsPath(startPos,showNBT)
  
  local oldSize = #KineticsPath.sourcePath
  KineticsPath.sourcePath = {}
  local path = KineticsPath.make(startPos)
  -- local path = kineticsPath.make(block:getPos())
  KineticsPath.setPath(path,oldSize)

  local block = world.getBlockState(startPos)
  -- local blockData = block:getEntityData()
  -- kineticsPath.firstNBT = (showNBT or nil) and blockData and toJson(blockData.BlockEntityTag)
  
  KineticsPath.firstNBT = (showNBT and block or nil) and block:toStateString()

  -- kineticsPath.updateRender()
  KineticsPath.changeRender()
  KineticsPath.updateRender()
end

function KineticsPath.blockData(block)
  local state = block:toStateString()
  local comparator = block:getComparatorOutput()

  local combined = state .. ((comparator ~=0) and (":::"..comparator..":::") or "")

  return Utils.string.prettierLists(combined)
end

function KineticsPath.updateNBT()

  if not KineticsPath.sourcePath[1] then
    KineticsPath.firstNBT = nil
    return
  end
  
  local block = world.getBlockState(KineticsPath.sourcePath[1].pos)
  -- local blockData = block:getEntityData()
  -- kineticsPath.firstNBT = (showNBT or nil) and blockData and toJson(blockData.BlockEntityTag)
  
  KineticsPath.firstNBT = (KineticsPath.firstNBT and block) and KineticsPath.blockData(block)
end


function pings.dismissSharedKineticsPath(hostToo)
  if hostToo or not host:isHost() then
    KineticsPath.setPath({})
  end
end

pings.localKineticsPath = localKineticsPath

local function pingLightKinetics(shared,showNBT)
  if host:isHost() then
    local block, hitPos, side = host:getPickBlock()
    if not block then return end
    if shared then
      pings.localKineticsPath(block:getPos(),showNBT)
    else
      localKineticsPath(block:getPos(),showNBT)
      pings.dismissSharedKineticsPath()
    end

  end
end


-- iconsKey:setOnPress(function(a,b) 
--   print(a,b)
--   pingLightKinetics() end)

local mainPage = action_wheel:newPage("mainPage")
action_wheel:setPage(mainPage)


mainPage:newAction()
    :title("Dismiss Kinetic Path")
    :item("minecraft:red_stained_glass")
    :hoverColor(0.5, 0.5, 0.75)
    :onLeftClick(function()
      pings.dismissSharedKineticsPath(true)
    end):onRightClick(function()
      if type(KineticsPath.firstNBT) == "string" then
        host:setClipboard(KineticsPath.firstNBT)
      end
    end)


mainPage:newAction()
    :title("Share Kinetic Path")
    :item("minecraft:orange_stained_glass")
    :hoverColor(0.5, 0.5, 1)
    :onLeftClick(function()
      pingLightKinetics(true,false)
    end):onRightClick(function()
      pingLightKinetics(true,true)
    end)

mainPage:newAction()
    :title("Kinetic Path")
    :item("minecraft:blue_stained_glass")
    :hoverColor(0.5, 0.5, 1)
    :onLeftClick(function()
      pingLightKinetics(false,false)
    end):onRightClick(function()
      pingLightKinetics(false,true)
    end)

--tick event, called 20 times per second
function events.tick()
  --code goes here
  -- kineticsPath.updateRender()
  if avatar:getPermissionLevel() == "max" or host:isHost() then
    KineticsPath.updateNBT()
    KineticsPath.changeRender()
  end
  KineticsPath.updateRender()


end
