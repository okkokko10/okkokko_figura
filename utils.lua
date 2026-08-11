Utils = {}

Utils.Sublevel = {}

-- copied from https://discord.com/channels/1129805506354085959/1234218592187453452/1499007047818154054 
-- we have to raycast twice because sublevel rotation gives some offset
local _sabelSubLevelOffset = vec(0, 10000, 0)

--- copied from https://discord.com/channels/1129805506354085959/1234218592187453452/1499007047818154054 
---@param pos Vector3
---@return Vector3
function Utils.Sublevel.sableSublevelToWorld(pos)
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

---comment
---@param pos Vector
---@return Matrix
---@return Vector
function Utils.Sublevel.sublevelRotationMatrix3(pos)
  if not pos then
    error("pos not given")
  end
  if not Utils.Sublevel.isInSublevel(pos) then
    return matrices.mat3(),pos
  end
  local center = Utils.Sublevel.sableSublevelToWorld(pos)
  local x = Utils.Sublevel.sableSublevelToWorld(pos + vec(1,0,0))
  local y = Utils.Sublevel.sableSublevelToWorld(pos + vec(0,1,0))
  local z = Utils.Sublevel.sableSublevelToWorld(pos + vec(0,0,1))

  return matrices.mat3(x-center,y-center,z-center),center
  
end

function Utils.Sublevel.sublevelRotationMatrix(pos)
  return Utils.Sublevel.sublevelRotationMatrix3(pos):augmented()
end

function Utils.Sublevel.sublevelRotationMatrixInv3(pos)
  if not Utils.Sublevel.isInSublevel(pos) then
    return matrices.mat3()
  end
  return Utils.Sublevel.sublevelRotationMatrix3(pos):invert()
end

function Utils.Sublevel.sublevelRotationMatrixInv(pos)
  if not Utils.Sublevel.isInSublevel(pos) then
    return matrices.mat4()
  end
  return Utils.Sublevel.sublevelRotationMatrix3(pos):invert():augmented()
end



function Utils.Sublevel.isInSublevel(pos)
  return pos.x > 20000000
end

function Utils.Sublevel.nilInAerospace(pos)
  return (not Utils.Sublevel.isInSublevel(pos) or nil) and pos
end


PS = 16


---the position matrix of the coordinate in world space.
---the materialized coordinate is in the origin.
---by default multiplies the coordinate by 16
---@param pos Vector3
---@param posScaling? number
---@return Matrix
---@return boolean loaded
function Utils.Sublevel.sublevelPositionMatrix(pos,posScaling)
  local mat,v = Utils.Sublevel.sublevelRotationMatrix3(pos)
  local worked = not Utils.Sublevel.isInSublevel(v)
  return mat:augmented():translate((posScaling or PS) * v),worked
end



-- https://stackoverflow.com/questions/51181222/lua-trailing-space-removal
function stripWhitespace(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

Utils.ID = {}



---@package
Utils._idConstructors = {}

---using Utils.ID.from() with an unregistered ID of form !<keyword>:<arg> registers it as an ID corresponding to this func
---@generic S
---@param keyword string
---@param func fun(arg:string):S|nil
function Utils.registerIDConstructor(keyword,func)
  Utils._idConstructors[keyword] = func
end


---@package
---creates a new object if it doesn't exist yet.
---@generic S
---@param id ID<S>
---@param checkType? Type<S>
---@return S|nil
function Utils.constructFromID(id,checkType)
  if type(id) ~= "string" then return end
  local _, _, keyword, name =  string.find(id,"^!(.*):(.*)$")
  if keyword then
    local f =Utils._idConstructors[keyword]
    if f then
      log("constructing: ",keyword,name,f)
      local out = f(name)
      return out
    else
      log("unrecognized keyword:",keyword, "used with",name)
    end
    -- return Positioning.playerNameFollower(name)
  end
  

end

--- Utils.ID.set and Utils.ID.from using a field
Utils.ID.field = setmetatable({},{
  ---@generic S
  ---@param t any
  ---@param k ID<S>
  ---@return S
  __index = function (t, k)
    return Utils.ID.from(k)
  end,
  ---@generic S
  ---@param t any
  ---@param k ID<S>
  ---@param v S
  __newindex = function (t, k, v)
    Utils.ID.set(v,k)
  end
})


---@package
Utils._idInv = {}
---@package
Utils._ids = {}

---@generic S
---@param self S
---@param id ID<S>
---@return S
function Utils.ID.set(self,id)
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
function Utils.ID.from(id,checkType)
    local w = Utils._idInv[id]
    if id and not w then
      w = Utils.constructFromID(id)
      if w then
        Utils.ID.set(w,id)
      end
    end

    if checkType and type(w) ~= checkType then
      error("id " .. id .. " was expected to be " .. checkType .. ", instead was " .. type(w))
    end
    return w
end

Utils.ID.isID = Utils.ID.from -- temp
Utils.ID.hasID = Utils.ID.get -- temp


---@generic S
---@param self S
---@return ID<S>|nil
function Utils.ID.get(self)
    return Utils._ids[self]
end

---@generic S
---@alias IDS<S> S|ID<S>

---@generic S
---@param ids IDS<S>
---@param checkType? Type<S>
---@return S|nil
function Utils.ID.materialize(ids,checkType)
  if type(ids) == "string" then
    return Utils.ID.from(ids,checkType)
  else
    return ids
  end
end

---@generic S
---@return { [ID<S>] : S }
function Utils.ID.listIDd()
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
  class.setID = Utils.ID.set
  class.fromID = Utils.ID.from
  class.getID = Utils.ID.get
  return class
end


function Utils.setMatrixPos(matrix,pos)
  return matrix:translate(-matrix:getColumn(4).xyz+pos)
end


function Utils.vectorString(vector)
  return table.concat({vector:unpack()}," ")
end

Utils.math = {}



return Utils