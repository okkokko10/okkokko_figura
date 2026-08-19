



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
        local origin = vec(bit32.band(bit32.bnot(0x7FF),pos.x),0,bit32.band(bit32.bnot(0x7FF),pos.z)) + 0x400
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
---@field end_pos VectorWithLayer -- if status=="root_reached", is the location of the root. else, is the location of the first invalid position
---@field penultimate_pos VectorWithLayer?  -- if status=="root_reached", is the location prior to root. else, is the location of the last valid position
---@field status KineticPathStatus?
---@field last_valid_pos VectorWithLayer? -- basically path[length].pos


---@class PathNodeData<S>
---@field pos VectorWithLayer
-- ---@field isExtraKinetics boolean
---@field blockId string
---@field source_pos? VectorWithLayer
-- ---@field connectedToExtraKinetics boolean
---@field index integer
---@field previous? S
---@field prev_difference Vector|false|nil -- Vector: relative position of previous path node. can be 0. false: previous path node in different sublevel. nil: start of list
---@field next_difference Vector|false|nil -- Vector: relative position of next(source) path node. can be 0. false: next path node in different sublevel. nil: end of list
---@field common KineticPathCommonData

---@class KineticData
---@field Id number -- network
---@field Stress number -- network
---@field Capacity number -- network
---@field Size number -- network
---@field Speed number -- information.
---@field AddedStress number -- information.
---@field AddedCapacity number -- information


---@class KineticPathNodeData : KineticData, PathNodeData<KineticPathNodeData>



---@alias KineticPathStatus "exceeds_length"|"unloaded"|"not_block_entity"|"no_network"|"root_reached"

---@class KineticPath
---@field start_pos VectorWithLayer
---@field path? KineticPathNodeData[]|false
---@field common KineticPathCommonData?
---@field part ModelPart?
---@field path_parts ModelPart[]?
local KineticPath = {
  pathLength = 32,
--   -@type KineticPathNodeData[]
--   sourcePath = {}, -- {x,y,z,type}
}
KineticPath.__index = KineticPath


---@param pathNodeData PathNodeData<KineticData>
---@param blockData NetworkBlockData
---@param idOrEK string?
---@param block unknown
---@return KineticPathNodeData
function KineticPath:addKineticData(pathNodeData,blockData, idOrEK, block)
        for key, value in pairs((blockData).Network or {}) do
            pathNodeData[key] = value
        end
        ---@diagnostic disable-next-line: inject-field
        pathNodeData.Speed = blockData.Speed
        return pathNodeData
end

--- can also be a ExtraKinetic component
---@alias NetworkBlockData table

--- just searches the table for any value that could be ExtraKinetics
---relies on assumption: an inner table in nbt is ExtraKinetics iff it contains a field `NeedsSpeedUpdate`
---@param blockData NetworkBlockData
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
---@param blockData NetworkBlockData
---@param idOrEK string?
---@param block unknown
---@return VectorWithLayer? Source
function KineticPath:getSource(blockData, idOrEK, block)
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
---@return NetworkBlockData? data
---@return string blockIdOrExtraKinetic
---@return unknown block
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


---comment
---@param blockData NetworkBlockData|nil
---@param idOrEK string?
---@param block unknown
---@return string|nil
function KineticPath:validateBlockData(blockData, idOrEK, block)
        if not blockData then
            -- either not loaded, or something weirder (or just the first block. append "_start" to the status if i==1. or return the index).
            -- todo: differentiate between being unloaded in the same level and in different levels
            if block.id == "minecraft:void_air" then -- void_air exists in unloaded chunks and beyond the build height limits. so technically this branch could also occur when a source is somehow above the build height limit.
                -- normal if on the ground, weird if the last vertex is on a sublevel.
                -- todo: report somewhere on whether the last connection is across (sub)levels.
                return "unloaded"
            else
                -- it would be strange if this happened outside of i==1. a kinetic source that isn't a block entity.
                return "not_block_entity"
            end
        else
            local network = blockData.Network
            -- hm, technically this check doesn't have to be required, and if omitted could track other relationships where "Source" points toward a root. 
            if not (network and network.Stress) then -- there exist nbt components titled "Network" other than kinetic networks, such as big radars data networks
            --- block isn't in a kinetic network.
            --- happens if it isn't an active kinetic block.
            --- it would be odd if this happened outside i==1
            return "no_network"
            end
        end
end

--- todo: maybe abstract it so you can track more kinds of networks with it.
---@param pos VectorWithLayer
---@param pathEnd number
---@param pathStart number?
---@param path KineticPathNodeData[]|false? if false (not nil), discards the intermediate path. todo: still saves the second-to-last to determine if the unloaded endpoint is in a different (sub)level
---@param common? KineticPathCommonData
---@return KineticPathNodeData[]|false
---@return KineticPathCommonData common
function KineticPath:make(pos, pathEnd, pathStart, path,common)
    -- pathEnd = pathEnd
    ---@type KineticPathNodeData[]?
    if path ~= false then
        path = path or {}
    end

    local status = "exceeds_length"
    local prevPos
    local connectedToExtraKinetics = false

    common = common or {}

    common.start_pos = common.start_pos or pos
    for i = pathStart or (#(path or {}) + 1), pathEnd do
      local blockData, idOrEK, block = self:getData(pos)

      -- ---@type {Network: {Id:number,Stress:number,Capacity:number,Size:number}?, Speed:number, Source:{[1]:number,[2]:number,[3]:number}? }?
      local st = self:validateBlockData(blockData,idOrEK, block )
      if st then
        status = st
        break
      end
      ---@cast blockData -?
      
      
      common.length = i
      common.last_valid_pos = pos

      local source_vec = self:getSource(blockData, idOrEK, block)
      
      if path then
        
        -- local network = blockData.network
        local prev_difference = prevPos and (Utils.Sublevel.difference(VectorWithLayer.getVector(prevPos), VectorWithLayer.getVector(pos)) or false)
        local next_difference = source_vec and (Utils.Sublevel.difference(VectorWithLayer.getVector(source_vec), VectorWithLayer.getVector(pos)) or false)
        path[i] = self:addKineticData({
            pos=pos,
            blockId = idOrEK,
            source_pos = source_vec,
            index = i,
            previous = path[i-1],
            prev_difference = prev_difference,
            next_difference = next_difference,
            common = common
            },blockData, idOrEK, block
            )
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
    -- common.length = i1
    common.end_pos = pos
    common.penultimate_pos = prevPos
    common.status = status

    return path,common
end



function KineticPath.create(pos)
    local out = setmetatable({start_pos = pos},KineticPath)
    return out
end

--- keeps stuff like status but updates stuff like start_pos
---@param current KineticPathCommonData
---@param new KineticPathCommonData
---@return KineticPathCommonData new
function KineticPath:mergeCommon(current,new)
    for key, value in pairs(new) do
        if key ~= "start_pos" then
            current[key] = value
        end
    end
    return current
end

---disables tracking the path. only gathers common with :extend
---@return KineticPath
function KineticPath:disablePath()
    self.path = false
    return self
end

function KineticPath:extend(pathLength)
    local start = (self.common or {}).length
    local path, common =  KineticPath:make((self.common or {}).last_valid_pos or self.start_pos,(start or 1) + pathLength - 1,start,self.path,self.common)
    self.path =  path
    self.common = common
    return self
end

function KineticPath:remove()
    if self.part then
        self.part:remove()
        self.part = nil
    end
    self.removed = true
end

-- function KineticPath.remove_all()
--     for key, value in pairs(KineticPath.instances) do
--         value:remove()
--     end
--     KineticPath.instances = {}
-- end


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
            -- {"isStart",invert=true},
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

---if ticks is a number, this is removed in that amount of ticks
---@param ticks number?
---@return self
function KineticPath:setLifetime(ticks)
    if ticks then
        (require"Sleep"):queue(ticks,self.remove,self)
    end
    return self
end
function KineticPath:lengthenEveryTicks(byLength,ticks,lifetimeAfter)
    if (not self.removed) and ((not self.common) or self.common.status == "exceeds_length" or self.common.status == "unloaded") then
        self:extendVisual(byLength or 1)
        require("Sleep"):queue(ticks or 1, self.lengthenEveryTicks, self, byLength, ticks)
    else
        self:setLifetime(lifetimeAfter)
        log(self.common.end_pos)
    end
    return self
end


function KineticPath:pre_init_pathPart(i)
    local node = self.path[i]
    if not node then
        -- error("somehow pre-initializing without having a path. i = " .. i)
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
    for i, node in pairs(self.path or {}) do
        self:pre_init_pathPart(i)
    end
    return self
end

---creates a model that displays this.
---@param from number?
---@param to number?
function KineticPath:resetVisual(from,to)
    for i = from or 1, to or self.common.length do
        if self.path_parts[i] then
            self.path_parts[i]:remove()
            self.path_parts[i] = nil
        end
        self:pre_init_pathPart(i)
    end
    return self
end

function KineticPath:extendVisual(pathLength)
    local start = (self.common or {}).length
    return self:extend(pathLength+1):resetVisual(start,(start or 1) + pathLength )
end

function KineticPath.test(pathLength,lifetime,byLength,ticks)
    
  if host:isHost() then
    local block, hitPos, side = host:getPickBlock()
    if not block then return end
    local pos = block:getPos()
    local p = KineticPath.create(pos)
        :createVisual(models,"kineticTest")
        :extendVisual(pathLength or 32)
        :lengthenEveryTicks(byLength or 2,ticks or 1,lifetime)
        -- :setLifetime(lifetime)
    log(p)
  end
end




return KineticPath