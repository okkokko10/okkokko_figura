
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
  return (str or ""):gsub(",",",\n"):gsub("{","{\n")
  else
    return (str or ""):gsub(",", ", "):gsub("{","{ ")

  end
end


function levelRotationMatrix(pos)
  if not pos then
    error("pos not given")
    return matrices.mat4()
  end
  -- log("levelRotationMatrix")
  local center = sableSublevelToWorld(pos)
  local x = sableSublevelToWorld(pos + vec(1,0,0))
  local y = sableSublevelToWorld(pos + vec(0,1,0))
  local z = sableSublevelToWorld(pos + vec(0,0,1))
  -- log("levelRotationMatrix end")

  return matrices.mat3(x-center,y-center,z-center):augmented()
  
end

PS = 16

-- https://stackoverflow.com/questions/51181222/lua-trailing-space-removal
function stripWhitespace(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end