



--- plans:
--- function to create a KineticPath object
--- method that creates a visual for the KineticPath
--- method to discard that visual.










---comment
---@param pos Vector
---@return Vector
---@return Vector
function Utils.Sublevel.getSublevelOriginOffset(pos)
    if Utils.Sublevel.isInSublevel(pos) then
        local origin = vec(bit32.band(bit32.bnot(0x7FF),pos.x),0,bit32.band(bit32.bnot(0x7FF),pos.z))
        -- log("sublevel origin offset:", pos, origin, pos-origin)
        return origin, pos-origin
    else
        return vec(0,0,0), pos
    end
end


---not exact. relies on a (possibly unfounded) assumption that sublevels will not be over 1000 blocks in diameter
--- not used for important logic here
---returns true if both are in the world
---@param pos1 Vector
---@param pos2 Vector
---@return boolean
function Utils.Sublevel.areInSameSublevel(pos1,pos2)
    return Utils.Sublevel.getSublevelOriginOffset(pos1) == Utils.Sublevel.getSublevelOriginOffset(pos2)
  
end

---returns pos1-pos2 if they are in the same sublevel, otherwise returns nil
---@param pos1 Vector
---@param pos2 Vector
---@return Vector|nil
function Utils.Sublevel.difference(pos1,pos2)
    return Utils.Sublevel.areInSameSublevel(pos1,pos2) and (pos1-pos2) or nil
end

--- Vector<4> that encodes a 3d position and whether it points to Extra Kinetics. get the original with .xyz
---@alias VectorWithLayer Vector<4>|Vector<3>
local VectorWithLayer = {}

function VectorWithLayer.fromVectorAndPointingToExtraKinetics(vec,ek)
    return vec:augmented(ek and 1 or 0)
end

---comment
---@param vecWL VectorWithLayer
---@return Vector
function VectorWithLayer.getVector(vecWL)
    return vecWL.xyz
end
---comment
---@param vecWL VectorWithLayer
---@return boolean extraKinetics
function VectorWithLayer.isPointingToExtraKinetics(vecWL)
    return vecWL.w == 1
end

---@class Vector
---@field xyz Vector
---@field w number

---@class KineticPathCommonData
---@field start_pos VectorWithLayer
---@field length number
---@field end_pos VectorWithLayer
---@field penultimate_pos VectorWithLayer?
---@field status KineticPathStatus?


---@class KineticPathNodeData
---@field pos VectorWithLayer
-- ---@field isExtraKinetics boolean
---@field Id number -- network
---@field Stress number -- network
---@field Capacity number -- network
---@field Size number -- network
---@field Speed number -- information.
---@field blockId string
---@field source_pos? VectorWithLayer
-- ---@field connectedToExtraKinetics boolean
---@field index integer
---@field previous? KineticPathNodeData
---@field prev_difference Vector|false|nil -- Vector: relative position of previous path node. can be 0. false: previous path node in different sublevel. nil: start of list
---@field next_difference Vector|false|nil -- Vector: relative position of next(source) path node. can be 0. false: next path node in different sublevel. nil: end of list
---@field common KineticPathCommonData

---@alias KineticPathStatus "exceeds_length"|"unloaded"|"not_block_entity"|"no_network"|"root_reached"

---@class KineticPath
---@field start_pos VectorWithLayer
---@field path? KineticPathNodeData[]
---@field length number
---@field end_pos VectorWithLayer
---@field penultimate_pos VectorWithLayer?
---@field status KineticPathStatus?
---@field part ModelPart?
---@field path_parts ModelPart[]?
local KineticPath = {
  pathLength = 32,
--   -@type KineticPathNodeData[]
--   sourcePath = {}, -- {x,y,z,type}
}
KineticPath.__index = KineticPath

--- just searches the table for any value that could be ExtraKinetics
---relies on assumption: an inner table in nbt is ExtraKinetics iff it contains a field `NeedsSpeedUpdate`
---@param blockData table
---@return table? ExtraKinetics
---@return string? key
function KineticPath:getExtraKinetics(blockData)
    for key, value in pairs(blockData) do
        if type(value) == "table" and key ~= "BlockEntityTag" then
            if value.NeedsSpeedUpdate then
                return value, key
            end
        end
    end
    return nil
end

---comment
---@param blockData table
---@return VectorWithLayer? Source
function KineticPath:getSource(blockData)
    if not blockData then
        return
    end
    local source = blockData.Source
    if not source then
        return
    end
    local source_vec = vec(table.unpack(source))
    local ConnectedToExtraKinetics = blockData.ConnectedToExtraKinetics == 1
    return VectorWithLayer.fromVectorAndPointingToExtraKinetics(source_vec, ConnectedToExtraKinetics)
end

---comment
---@param pos VectorWithLayer
---@return table? data
---@return string blockIdOrExtraKinetic
---@return table block
function KineticPath:getData(pos)
    local block = world.getBlockState(VectorWithLayer.getVector(pos))
    local blockData = block:getEntityData()
    if not blockData then return nil, block.id, block end
    if VectorWithLayer.isPointingToExtraKinetics(pos) then
        local ek, key =  self:getExtraKinetics(blockData)
        return ek, key or "", block
    else
        return blockData, block.id, block
    end
end


--- todo: maybe abstract it so you can track more kinds of networks with it.
---@param pos VectorWithLayer
---@param pathLength number?
---@param noList boolean? if true, discards the intermediate path. todo: still saves the second-to-last to determine if the unloaded endpoint is in a different (sub)level
---@return KineticPathNodeData[]
---@return number length
---@return VectorWithLayer endpoint
---@return VectorWithLayer? penultimate_point
---@return KineticPathStatus status 
function KineticPath:make(pos,pathLength,noList)
    pathLength = pathLength or self.pathLength
    ---@type KineticPathNodeData[]
    local path = {}
    local status = "exceeds_length"
    local i1
    local prevPos
    local connectedToExtraKinetics = false

    local common = {}
    
    common.start_pos = pos
    for i = 1, pathLength do
      local blockData, idOrEK, block = self:getData(pos)

      -- ---@type {Network: {Id:number,Stress:number,Capacity:number,Size:number}?, Speed:number, Source:{[1]:number,[2]:number,[3]:number}? }?

      if not blockData then
        -- either not loaded, or something weirder (or just the first block. append "_start" to the status if i==1. or return the index).
        -- todo: differentiate between being unloaded in the same level and in different levels
        if idOrEK == "minecraft:void_air" then -- void_air exists in unloaded chunks and beyond the build height limits. so technically this branch could also occur when a source is somehow above the build height limit.
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
      i1 = i

      local source_vec = self:getSource(blockData)
      
      if not noList then
        local prev_difference = prevPos and (Utils.Sublevel.difference(VectorWithLayer.getVector(prevPos), VectorWithLayer.getVector(pos)) or false)
        local next_difference = source_vec and (Utils.Sublevel.difference(VectorWithLayer.getVector(source_vec), VectorWithLayer.getVector(pos)) or false)
        path[i] = {
            pos=pos, 
            -- isExtraKinetics=connectedToExtraKinetics,
            blockId = idOrEK,
            source_pos = source_vec,
            -- connectedToExtraKinetics = connectedToExtra or false,
            index = i,
            previous = path[i-1],
            prev_difference = prev_difference,
            next_difference = next_difference,
            Id=network.Id,
            Stress = network.Stress,
            Capacity = network.Capacity,
            Size = network.Size,
            Speed = blockData.Speed,
            common = common
            }
        for key, value in pairs(network) do
            path[i][key] = value
        end
      end

      if not source_vec then
        -- a kinetic network vertex that does not have a source is a root.
        -- although I wonder, would it be possible for a network to have multiple roots?
        -- todo maybe: check whether the network id depends on the root position, making the root unique.
        status = "root_reached"
        break
      end
      prevPos = pos
      pos = source_vec
    --   connectedToExtraKinetics = connectedToExtra or false
    end
    common.length = i1
    common.end_pos = pos
    common.penultimate_pos = prevPos
    common.status = status

    return path,i1,pos,prevPos,status
end

KineticPath.instances = {}

function KineticPath.create(pos)
    local out = setmetatable({start_pos = pos},KineticPath)
    KineticPath.instances[#KineticPath.instances+1] = out
    return out
end
function KineticPath:extend(pathLength,noList)
    self.path, self.length, self.end_pos, self.penultimate_pos, self.status = KineticPath:make(self.start_pos,pathLength,noList)
    return self
end

function KineticPath:remove()
    if self.part then
        self.part:remove()
        self.part = nil
    end
end
function KineticPath.remove_all()
    for key, value in pairs(KineticPath.instances) do
        value:remove()
    end
    KineticPath.instances = {}
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
        Positioning.make.coordinateFollower(slOrigin,sublevelID,grandparent)
    end
    if type(part) == "ModelPart" then
        part:moveTo(grandparent[sublevelID])
    else
        
        part = grandparent[sublevelID]:newPart((type(part) == "string") and part or tostring(slOffset))
    end
    part:setPos(slOffset*PS)
    return part
end


function Utils.string.split(str)
    local out = {}
    for w in string.gmatch(str,"%S+") do
        out[#out+1] = w
    end
    return out
end

---takes parentheses and extracts their contents
---@param str string
---@return string
---@return { [string] : string }
function Utils.string.subconditions(str)
    local subcondition_sentinel = "SCa%daCS"
    local subconditions = {}
    local count = 1
    str = string.gsub(
        str,"%b()",function (s)
            local id = subcondition_sentinel:format(count)
            count = count + 1
            subconditions[id] = string.gsub(s,"^%((.*)%)$","%1")
            return id
        end
    )
    return str,subconditions
end

--- incomplete
function Utils.string.condition(str)
    
    local subconditions
    str,subconditions = Utils.string.subconditions(str)
    str = string.gsub(str,"|"," | ") --
    str = string.gsub(str,"%-%s*"," %-") -- formats `-` so it has a preceding space and no space between it and the next word
    str = string.gsub(str,"%s*=%s*","%=") -- formats `=` so there is no space between

    local out = {}
    for w in string.gmatch(str,"(%S+)") do
        
        out[#out+1] = w
    end

    return out
end

--- overrideable
KineticPath.pretty_rules = {
    {format = function (node_data)
        local succ, name = pcall(player.getName,player)
        if not succ then
            name = ""
        end
        return name .. "'s kinetic path"
    end, condition = "isStart"},
    {vars = "index", format = "(%i)", condition = "always"},
    {vars = "Id", format = "Kinetic Network %i", condition = "change"}, -- change looks at vars and checks whether they are equal to the previous
    {vars = "Stress Capacity", format = "%s/%s SU", condition = "change"},
    {vars = "AddedStress", format = "%s SU used", condition = "found"},
    {vars = "AddedCapacity", format = "%s SU added", condition = "found"},
    {vars = "Size", format = "size: %i", condition = "change"},
    {vars = "Speed", format = "%sRPM", condition = "change"},
    {format = "root", condition = {"isEnd",{key = "status", value = "root_reached", op = "equals"}, op = "and"}},
    {
        vars = "status", format = "status: %s",
        condition = {
            "isEnd",
            {key="status",value="root_reached",op = "equals", invert = true},
            {"isStart",invert=true},
            op = "and"}
    },
    {
        vars= "blockId",
        format = "EK: %s", condition = "isExtraKinetics"
    },
    {
        ---@param state KineticPathNodeData
        format = function (state)
            return "-> +"..(tostring(state.next_difference))
        end,
        condition = function (state)
            return state.next_difference and (state.next_difference:lengthSquared() ~= 1)
        end,
    },
    {
        ---@param state KineticPathNodeData
        format = function (state)
            return "continues at " .. tostring(state.source_pos.xyz)
        end,
        condition = function (state)
            return (state.next_difference == false)
        end,
    },
    {
        format = "->EK", condition = "connectedToExtraKinetics"
    }
    -- {mode = "ExtraKinetics"} -- write text for extra kinetics in the same block, on the same text
}


---comment
---@param state KineticPathNodeData
---@param var string
---@return boolean success
---@return any
function KineticPath:state_get(state,var)
    local out = state[var] or state.common[var]
    if out ~= nil then
        return true,out
    end
    return false
end

---@type {[string] : fun(self:KineticPath,state:KineticPathNodeData,vars):boolean}
KineticPath.condition_words = {
            always = function (self,state,vars)
                return true
            end,
            change = function (self,state,vars)
                if not state.previous then
                    return true
                end
                for key, value in pairs(vars) do
                    local r, v = self:state_get(state,value)
                    local r2, v2 = self:state_get(state.previous,value)
                    if r ~= r2 or v ~= v2 then
                        return true
                    end
                end
                return false
            end,
            found = function (self,state,vars)
                for key, value in pairs(vars) do
                    local r, v = self:state_get(state,value)
                    if not r then
                        return false
                    end
                end
                return true
            end,
            
            isEnd = function (self,state,vars)

                return state.index == state.common.length
            end,
            isStart = function (self,state,vars)
                return state.index == 1
            end,
            isExtraKinetics = function (self,state,vars)
                return VectorWithLayer.isPointingToExtraKinetics(state.pos)
            end,
            connectedToExtraKinetics = function (self,state,vars)
                return state.source_pos and VectorWithLayer.isPointingToExtraKinetics(state.source_pos) or false
            end,
}

---@type {[string] : fun(self:KineticPath,state:KineticPathNodeData,vars,condition:table):boolean}
KineticPath.condition_ops = {
            ["and"] = function (self,state,vars,condition)
                for index, value in ipairs(condition) do
                    if not self:pretty_condition(state,vars,value) then
                        return false
                    end
                end
                return true
            end,
            ["or"] = function (self,state,vars,condition)
                for index, value in ipairs(condition) do
                    if self:pretty_condition(state,vars,value) then
                        return true
                    end
                end
                return false
            end,
            ["equals"] = function (self,state,vars,condition)
                local r,v = self:state_get(state,condition.key)
                return v == condition.value
            end,
            
            ["ternary"] = function (self,state,vars,condition)
                if self:pretty_condition(state,vars,condition[1] or condition.cond or condition.c or condition.condition) then
                    return self:pretty_condition(state,vars,condition[2] or condition.left or condition.t)
                else
                    return self:pretty_condition(state,vars,condition[3] or condition.right or condition.e)
                end
            end,
            
}


function KineticPath:pretty_condition(state,vars,condition)
    if type(condition) == "string" then
        local f = self.condition_words[condition]
        if not f then
            -- error has occured
            log("unknown condition word:",condition)
            return false
        end
        return f(self,state,vars)

    elseif type(condition) == "table" then
        local f = self.condition_ops[condition.op or "and"]
        if not f then
            -- error has occured
            log("unknown condition op:",tostring(condition.op))
            return false
        end
        local out = f(self,state,vars,condition)
        return ((not out) ~= (not condition.invert))
    elseif type(condition) == "function" then
        local succ,r = pcall(condition,state,vars)
        if not succ then
            log("error in condition:",r)
            return false
        end
        return r
    end
    if condition == nil then
        return true
    end
    if condition == true then
        return true
    end
    if condition == false then
        return false
    end



    
end


function KineticPath:pretty_line(state,line)
    local vars = Utils.string.split(line.vars or "")
    local cond = self:pretty_condition(state,vars,line.condition)
    if not cond then
        return
    end
    local vars_material = {}
    for index, value in ipairs(vars) do
        local r, v = self:state_get(state,value)
        vars_material[index] = v
    end
    local succ, str
    if type(line.format) =="string" then
        succ, str = pcall(string.format,line.format,table.unpack(vars_material))
    elseif type(line.format) == "function" then
        succ, str = pcall(line.format,state,table.unpack(vars_material))
    end
    if not succ then
        str = "ERROR: vars " .. tostring(line.vars) .. " not applicable to format " .. tostring(line.format) .. ". message: " .. tostring(str)
    end
    return str
end



---@param node_data KineticPathNodeData
---@return string
function KineticPath:make_text(node_data)
    local lines = {}
    for index, value in ipairs(self.pretty_rules) do
        lines[#lines+1] = self:pretty_line(node_data,value)
    end
    return table.concat(lines,"\n")
end






---overrideable.
---@param path_part ModelPart
---@param node_data KineticPathNodeData
---@return Vector|nil color
function KineticPath:textBgColor(path_part,node_data)
    return vectors.intToRGB((((node_data.Id or 0) % 0x1001000) * (2654435761 % 0x1000000)))* 0.9
end

---overrideable.
---@param path_part ModelPart
---@param node_data KineticPathNodeData
function KineticPath:init_pathPart(path_part,node_data)
    local text = path_part:newPart("text","BILLBOARD"):newText("text")
        :setLight(15,15)
        :setWidth(16*4*3)
        :setScale(1/4)
        :setOpacity(0.5)
    if VectorWithLayer.isPointingToExtraKinetics(node_data.pos) then
        text:setAlignment("RIGHT")
    end

    if host:isHost() then
    end
    text:setSeeThrough(true)
    local colo = self:textBgColor(path_part,node_data)
    if colo then
        text:setBackground(true):setBackgroundColor(colo)
    end


    local t = self:make_text(node_data)
    text:setText(t)
    -- log(t)

    if node_data.next_difference and node_data.next_difference ~= vec(0,0,0) then
        local angle = Utils.math.directionToEulerAngle(-node_data.next_difference)
        path_part:newPart("to_next"):setRot(angle):setScale(1,1,node_data.next_difference:length())
        :newItem("glass")
        :setItem("light_blue_stained_glass")
        :setPos(vec(0,0,8))
        :setLight(15,15)
        :setScale(.5,.5,1)
        
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
    local main = Utils.Sublevel.moveToSublevelPosition(node.pos.xyz + 0.5,nil,self.part)
    self.path_parts[i] = main
    self:init_pathPart(main,node)
    
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
    return self
end



function KineticPath.test(pathLength,noList)
    
  if host:isHost() then
    local block, hitPos, side = host:getPickBlock()
    if not block then return end
    local pos = block:getPos()
    local p = KineticPath.create(pos)
        :extend(pathLength or 32,noList)
        :createVisual(models,"kineticTest")
    log(p)
  end
end




return KineticPath