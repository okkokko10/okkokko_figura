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

local iconsKey = keybinds:newKeybind("show named item icons", "key.keyboard.z", true)


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
    -- kineticsPath.modelPath[i].block_pointing1 = 
    --   kineticsPath.modelPath[i].block_pointing
    --   -- :newBlock("path"..i .. " block glass")
    --   -- :setBlock("light_blue_stained_glass")
      :newItem("glass")
        :setItem("light_blue_stained_glass")
        :setPos(vec(0,0,8))

        -- :setBlock("comparator")
        :setLight(15,15)
        -- :setPos(-vec(1,1,1) * 16 / 2)
        :setScale(.5,.5,1)
    local text = main:newPart("text","BILLBOARD"):newText("text")
      :setLight(15,15)
      -- :setPos(vec(1,1,0) * 16 / 2)
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




function KineticsPath.make(pos)

    -- local block, hitPos, side = host:getPickBlock()
    
    ---@type KineticPathNode[]
    local path = {}
    for i = 1, KineticsPath.pathLength do
      path[i] = {pos=pos}
      
      local block = world.getBlockState(pos)
      local blockData = block:getEntityData()
      if not blockData then break end
      local network = blockData.Network
      if not (network and network.Stress) then break end
      path[i].network = network
      local speed = blockData.Speed
      local source = blockData.Source
      if not source then
        break
      end

      -- logTable(network,5)
      -- log(speed)
      local source_vec = vec(table.unpack(source))
      pos = source_vec

      -- source_vec = source_vec + 1/2
      -- local sv = sableSublevelToWorld(source_vec)
      -- log(sv)
      -- models.target:setPos(sv*16)
      
    end
    
    -- if not (path[1] and path[1].network and path[1].network.Stress) then
    --   path = {}
    -- end



    return path
end

---@class vec3: Vector
---@field x number
---@field y number
---@field z number


---@class KineticPathNode
---@field pos vec3
---@field network? {Id:number,Stress:number,Capacity:number,Size:number}


-- kineticsPath.packingString = "dddLffl"

---comment
---@param node KineticPathNode
---@return "mat3"
function KineticsPath.packNode(node)
  local network = node.network or {}
  -- return string.pack(kineticsPath.packingString,node.pos.x,node.pos.y,node.pos.z,node.network)
  return matrices.mat3(node.pos,vec(network.Id or 0, network.Stress or 0,network.Capacity or 0),vec(network.Size or 0,0,0))
end

---@param matr Matrix
---@return KineticPathNode
function KineticsPath.unpackNode(matr)
  return {pos = matr:getColumn(1), network = {Id = matr:getColumn(2)[1],Stress = matr:getColumn(2)[2],Capacity = matr:getColumn(2)[3],Size = matr:getColumn(3)[1]}}
end

function KineticsPath.packPath(path)
  local packeds = {}
  for i = 1, #path do
    packeds[i] = KineticsPath.packNode(path[i])
  end
  return packeds
  
end

function KineticsPath.unpackPath(packedPath)
  local path = {}
  for i = 1, #packedPath do
    path[i] = KineticsPath.unpackNode(packedPath[i])
  end
  return path
  
end


-- function kineticsPath.


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

---@deprecated
function pings.newKineticsPath(isFinal,firstNBT,...)
  local tbl = table.pack(...)

  for i = 1, #tbl do
    if not tbl[i] then
      break
    end
    pingBuffer[#pingBuffer+1] = tbl[i]
  end
  if not isFinal then
    return
  end

  -- log("if you can see this please tell me this number: " .. #tbl)
  -- logTable(tbl)
  local path = KineticsPath.unpackPath(pingBuffer)
  pingBuffer = {}
  -- logTable(path,3)
  KineticsPath.setPath(path)
  
  KineticsPath.firstNBT = firstNBT

  -- kineticsPath.updateRender()
end

local function pingHeavyKinetics ()
  if host:isHost() then

    local block, hitPos, side = host:getPickBlock()
    
    if not block or block:getID() == "minecraft:air" then
      pings.newKineticsPath(true)
    
    else
      local blockData = block:getEntityData()
      local firstNBT = blockData and toJson(blockData.BlockEntityTag)
      local path = KineticsPath.make(block:getPos())
      local packedPath = KineticsPath.packPath(path)
      local batch = 5
      for i = 1, #packedPath, batch do
        pings.newKineticsPath(false, nil, table.unpack(packedPath,i,i+batch-1))
      end
      pings.newKineticsPath(true, firstNBT)

    end
    -- kineticsPath.setPath(path)
    -- log(block)
    -- logTable(kineticsPath.sourcePath,5)
    
  end
  
end

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
      host:setClipboard(KineticsPath.firstNBT)
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

  -- models.compassRoot.compass:setPos(16*(player:getPos())):setRot(0,compassRotation,0)
  -- models.compassRoot.compass

end

-- function events.world_render(delta)
-- end

-- --render event, called every time your avatar is rendered
-- --it have two arguments, "delta" and "context"
-- --"delta" is the percentage between the last and the next tick (as a decimal value, 0.0 to 1.0)
-- --"context" is a string that tells from where this render event was called (the paperdoll, gui, player render, first person)
-- function events.render(delta, context)

--   -- kineticsPath.updateRender()


--   -- if iconsKey:isPressed() then
--   --   log(delta,context)
--   -- end
--   -- if context == "MINECRAFT_GUI" then
--   --   local windowScale = client.getScaledWindowSize()/client.getWindowSize()
--   --   local mous = client.getMousePos() * windowScale
--   --   -- models.model.Item:setPos((-mous):augmented(-10000))

    
--   -- end
--   --code goes here
-- end

