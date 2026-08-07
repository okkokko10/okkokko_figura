
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


-- Source: https://discord.com/channels/1129805506354085959/1234218592187453452/1405878281164558407
do
  local _idx=figuraMetatables.ModelPart.__index
  function figuraMetatables.ModelPart.__index(self, idx)
    if idx=="getOBB" then
      return function(cube)
        assert(cube:getType()=="CUBE","CUBE expected, got "..cube:getType())
        local obb, pivot = {}, cube:getPivot()
        for _, verts in pairs(cube:getAllVertices()) do
          assert(#verts==24,"All 6 sides must use the same texture")
          for i=1,8 do
            table.insert(obb,cube:partToWorldMatrix():apply(verts[i]:getPos()-pivot))
          end
        end
        return obb
      end
    end
    return _idx(self,idx)
  end
  ---@class RaycastAPI
  local rcst = figuraMetatables.RaycastAPI.__index
  ---@return table? obb
  ---@return Vector3? hitpos
  ---@return Entity.blockSide? side
  ---@return integer? index
  function rcst:obb(startpos, endpos, obbs)
    local hits={}
    for i,obb in ipairs(obbs) do
      local cntr=vec(0,0,0)
      for _,corner in ipairs(obb) do
        cntr=cntr+corner
      end
      cntr=cntr/8
      local min,max,x,y,z = obb[2],obb[7],(obb[1]-obb[2]):normalized(),(obb[3]-obb[2]):normalized(),(obb[5]-obb[2]):normalized()
      local lclToWrld = matrices.mat4(x.xyz_,y.xyz_,z.xyz_,cntr:augmented())
      local wrldToLcl = lclToWrld:inverted()
      local _,hit,side = self:aabb(wrldToLcl:apply(startpos),wrldToLcl:apply(endpos),{{wrldToLcl:apply(min),wrldToLcl:apply(max)}})
      if hit then table.insert(hits, {obb, hit and lclToWrld:apply(hit), side, i}) end
    end
    table.sort(hits, function(a, b)
      if not a[2] then return false end
      if not b[2] then return true end
      local da=(a[2]-startpos):length()
      local db=(b[2]-startpos):length()
      return da<db
    end)
    ---@diagnostic disable-next-line
    if hits[1] then return table.unpack(hits[1]) end
  end
end

-- Example
-- local obb,hitpos,side,i = raycast:obb(startpos, endpos, {cube:getOBB()})
