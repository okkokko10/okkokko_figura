Utils = {}


-- copied from https://discord.com/channels/1129805506354085959/1234218592187453452/1499007047818154054 
-- we have to raycast twice because sublevel rotation gives some offset
local _sabelSubLevelOffset = vec(0, 10000, 0)
---@param pos Vector3
---@return Vector3
function sableSublevelToWorld(pos)
  -- return pos
  local pos1 = pos + _sabelSubLevelOffset
  local pos2 = pos - _sabelSubLevelOffset
  local _, hitPos1 = raycast:block(pos1, pos1)
  local _, hitPos2 = raycast:block(pos2, pos2)
  return (hitPos1 + hitPos2) * 0.5
end


-- copied from https://discord.com/channels/1129805506354085959/1129811275380162730/1501029819964457130 
function directionToEulerAngle(dirVec)
    return vec(0, 180, 0)-vec(-math.deg(math.atan2(dirVec.y, dirVec.xz:length())), -math.deg(math.atan2(dirVec.x, dirVec.z)), 0)
end

NewlineLists = true

function prettierLists(str)
  if NewlineLists then
  return (str or ""):gsub(",",",\n"):gsub("{","{ ")
  else
    return (str or ""):gsub(",", ", "):gsub("{","{ ")

  end
end

function sublevelRotationMatrix3(pos)
  if not pos then
    error("pos not given")
  end
  if not isInSublevel(pos) then
    return matrices.mat3()
  end
  local center = sableSublevelToWorld(pos)
  local x = sableSublevelToWorld(pos + vec(1,0,0))
  local y = sableSublevelToWorld(pos + vec(0,1,0))
  local z = sableSublevelToWorld(pos + vec(0,0,1))

  return matrices.mat3(x-center,y-center,z-center)
  
end

function sublevelRotationMatrix(pos)
  return sublevelRotationMatrix3(pos):augmented()
end

function sublevelRotationMatrixInv3(pos)
  if not isInSublevel(pos) then
    return matrices.mat3()
  end
  return sublevelRotationMatrix3(pos):invert()
end

function sublevelRotationMatrixInv(pos)
  if not isInSublevel(pos) then
    return matrices.mat4()
  end
  return sublevelRotationMatrix3(pos):invert():augmented()
end


function isInSublevel(pos)
  return pos.x > 20000000
end

function nilInAerospace(pos)
  return (not isInSublevel(pos) or nil) and pos
end



PS = 16

-- https://stackoverflow.com/questions/51181222/lua-trailing-space-removal
function stripWhitespace(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end



---@package
Utils._idInv = {}
---@package
Utils._ids = {}

---@generic S
---@param self S
---@param id ID<S>
---@return S
function Utils.setID(self,id)
   if Utils._idInv[id] then
    error("multiple variables with id " .. id) -- .. " " .. _FloatingObject_ids[id] .. " " .. self)
   end
   if Utils._ids[self] then
    error("trying to add multiple ids to variable: " .. Utils._ids[self] .. " -> " .. id) -- .. " " .. Utils._ids[id] .. " " .. self)
   end
   Utils._ids[self] = id
   Utils._idInv[id] = self
   return self
end

---@generic S
---@param id ID<S>
---@param checkType? Type<S>
---@return S|nil
function Utils.fromID(id,checkType)
    local w = Utils._idInv[id]
    if id and not w then
      w = Utils.constructFromID(id,checkType)
      if w then
        Utils.setID(w,id)
      end
    end

    if checkType and type(w) ~= checkType then
      error("id " .. id .. " was expected to be " .. checkType .. ", instead was " .. type(w))
    end
    return w
end

---@generic S
---@param self S
---@return ID<S>|nil
function Utils.getID(self)
    return Utils._ids[self]
end

---@generic S
---@alias IDS<S> S|ID<S>

---@generic S
---@param ids IDS<S>
---@param checkType? Type<S>
---@return S|nil
function Utils.materializeID(ids,checkType)
  if type(ids) == "string" then
    return Utils.fromID(ids,checkType)
  else
    return ids
  end
end

---@generic S
---@return { [ID<S>] : S }
function Utils.listIDd()
  return Utils._idInv
end

---@generic S
---@class ID<S>


---@generic S
---@class IdUtil<S>
---@field setID fun(self:S,id:ID<S>):S
---@field fromID fun(id:ID<S>):S|nil
---@field getID fun(self:S):ID<S>|nil


---comment
---@generic S
---@param class IdUtil<S>
function Utils._registerIDChaining(class)
  class.setID = Utils.setID
  class.fromID = Utils.fromID
  class.getID = Utils.getID
  return class
end


function Utils.setMatrixPos(matrix,pos)
  return matrix:translate(-matrix:getColumn(4).xyz+pos)
end


function Utils.vectorString(vector)
  return table.concat({vector:unpack()}," ")
end

Utils.math = {}


---creates a new object if it doesn't exist yet.
---@generic S
---@param id ID<S>
---@param checkType? Type<S>
---@return S|nil
function Utils.constructFromID(id,checkType)
  if type(id) ~= "string" then return end
  local _, _, name =  string.find(id,"^!pl:(.*)$")
  if name then
    log(name)
    return Positioning.playerNameFollower(name)
  end
  

end



return Utils