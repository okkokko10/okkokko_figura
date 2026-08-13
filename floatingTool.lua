

-- objects that can follow the player but can be repositioned.
-- includes objects having multiple modes, and a state where objects briefly take on a certain mode, going back afterwards
-- follow player, with rotation, with head rotation
-- player mode where rotation is not registered so you can reach objects behind you
-- clicking objects with the mouse
-- go into freecam with any object
-- an object should have a "menu" state where it is in front of the player/camera so they can choose it.
-- maybe a gui

-- maybe a "table"
-- ooh, physics for objects on the table?

-- there are tools, and there are positions.


-- idea: Outer Wilds Projection Pools



---@deprecated

---@class HasPosSize
---@field pos vec3
---@field size vec3

---@class FloatingObject: IdUtil<FloatingObject>
---@field part ModelPart
---@field modeParents {[any]: ModelPart}
---@field modeStack any[]
---@field hitboxes {[any]: HasPosSize}
FloatingObject = {__type = "FloatingObject"}

require("utils")._registerIDChaining(FloatingObject)

function FloatingObject:new(o)
      o = o or {}
      setmetatable(o, self)
      self.__index = self
      return o
end

---@return FloatingObject
function FloatingObject:create(part,modeParents)
    return FloatingObject:new({part=part,modeParents=modeParents,modeStack={},hitboxes={}}):pushMode("base")
end


function FloatingObject.toPart(o)
    return o.part or o
end

function FloatingObject:getModeParent(mode)
    return self.modeParents[mode] or FloatingObject.fromID(mode) or mode
end


--- if mode is a local mode string, use it as is, otherwise look if it's a global id, and if so, use its value. otherwise use it as is (in this case it should be a part.)
---@param mode MultiMode
---@return any
function FloatingObject:convertModeKey(mode)
    if self.modeParents[mode] then
        return mode
    else
        return Utils.ID.get(mode) or mode
    end
    -- return (not self.modeParents[mode]) and FloatingObject.getID(mode) or mode
end




---@alias MoveTo fun(part:ModelPart,to:ModelPart)

---@deprecated
---@type MoveTo
function FloatingObject.moveToKeepPos(part,to)
    local o = to:partToWorldMatrix()
    local p = part:partToWorldMatrix()
    part:setMatrix(o:invert() * p)
    part:moveTo(to)
end


---@deprecated
---@type MoveTo
function FloatingObject.moveToKeepPosParent2(part,to)
    local o = to:getParent():partToWorldMatrix() -- goes wrong when `to` is itself ParentType "World"
    local p = (part:getParent() or part):partToWorldMatrix()
    to:setMatrix(o:invert() * p)
    part:moveTo(to)
end

---@type MoveTo
function FloatingObject.moveToKeepPosParent(part,to)
    local p = part:getParent():partToWorldMatrix()
    local matr = to:getPositionMatrix() * to:partToWorldMatrix():invert() * p
    to:setMatrix(matr)
    part:moveTo(to)
end
function FloatingObject.moveToKeepPosParentMatrix(part,to)
    local p = part:getParent():partToWorldMatrix()
    return to:getPositionMatrix() * to:partToWorldMatrix():invert() * p
end
function FloatingObject.moveToMatrix(part,to)
    return nil
end


---@class Mode

---@alias MultiMode Mode|ID<ModelPart>|ModelPart|string

---@alias SetMode fun(self: FloatingObject, mode: MultiMode, oldMode: MultiMode?, doPing: boolean?)
---@alias PushMode fun(self: FloatingObject, mode: MultiMode, doPing: boolean?):FloatingObject
---@alias PopMode fun(self: FloatingObject, mode: MultiMode?, doPing: boolean?)
---@alias SwapMode fun(self: FloatingObject, mode: MultiMode,oldMode:MultiMode?, doPing: boolean?):FloatingObject


function FloatingObject._make_setModePings(moveToMatrix)
    return function (self,mode,doPing)
        local mat = moveToMatrix(self.part,FloatingObject.toPart(self:getModeParent(mode)))
        if doPing then
            
            pings.foSetParentAndMatrix(self:getID(),mode,mat)
        else
            FloatingObject.foSetParentAndMatrix(self:getID() or self,mode,mat)
        end
    end
end


---@param moveTo MoveTo
---@return SetMode
function FloatingObject._make_setMode(moveTo)
    return function (self,mode,oldMode,doPing)
        moveTo(self.part,FloatingObject.toPart(self:getModeParent(mode)))
    end
end

function FloatingObject.foSetParentAndMatrix(fID,mode,matrix)
    local fo = FloatingObject.fromID(fID) or (type(fID) == "FloatingObject") and fID
    if not fo then error("not found:" .. (fID or "nil") .. " " .. (mode or "nil")) end
    local par = FloatingObject.toPart(fo:getModeParent(mode))
    if matrix then
        par:setMatrix(matrix)
    end
    fo.part:moveTo(par)
end

pings.foSetParentAndMatrix = FloatingObject.foSetParentAndMatrix



---@param moveTo MoveTo
---@return PushMode
function FloatingObject._make_pushMode(moveTo)
    local setMode = FloatingObject._make_setMode(moveTo)
    return function (self,mode,doPing)
        local mode1 = self:convertModeKey(mode)
        self.modeStack[#self.modeStack+1] = mode1
        setMode(self,mode1)--,self.modeStack[#self.modeStack-1])
        return self
    end
end

---@return PushMode
function FloatingObject._make_pushModePings(moveToMatrix)
    local setMode = FloatingObject._make_setModePings(moveToMatrix)
    return function (self,mode,doPing)
        local mode1 = self:convertModeKey(mode)
        self.modeStack[#self.modeStack+1] = mode1
        setMode(self,mode1,doPing)--,self.modeStack[#self.modeStack-1])
        return self
    end
end


---@param moveTo MoveTo
---@return PopMode
function FloatingObject._make_popMode(moveTo)
    local setMode = FloatingObject._make_setMode(moveTo)
    return function (self,mode)
        local old = self.modeStack[#self.modeStack]
        if (mode and self:convertModeKey(mode) ~= old) or #self.modeStack <= 1 then return end
        self.modeStack[#self.modeStack] = nil
        setMode(self,self.modeStack[#self.modeStack])--,old)
        -- return old
    end
end
---@return PopMode
function FloatingObject._make_popModePings(moveToMatrix)
    local setMode = FloatingObject._make_setModePings(moveToMatrix)
    return function (self,filterOldMode)
        local old = self.modeStack[#self.modeStack]
        if (filterOldMode and self:convertModeKey(filterOldMode) ~= old) or #self.modeStack <= 1 then return end
        self.modeStack[#self.modeStack] = nil
        setMode(self,self.modeStack[#self.modeStack])--,old)
        -- return old
    end
end

--- directly pops and pushes the stack, moving the parent directly.
---@return SwapMode
function FloatingObject._make_swapModePings(moveToMatrix)
    local setMode = FloatingObject._make_setModePings(moveToMatrix)
    return function (self,mode,filterOldMode,doPing)
        local old = self.modeStack[#self.modeStack]
        if (filterOldMode and self:convertModeKey(filterOldMode) ~= old) then return self end
        local mode1 = self:convertModeKey(mode)
        self.modeStack[#self.modeStack] = mode1
        setMode(self,mode1,doPing)--,self.modeStack[#self.modeStack-1])
        return self
    end
end


-- FloatingObject._setModeKeepPos = FloatingObject._make_setMode(FloatingObject.moveToKeepPos)



-- FloatingObject._setMode = FloatingObject._make_setMode(models.moveTo)
FloatingObject.pushMode = FloatingObject._make_pushMode(models.moveTo)
FloatingObject.popMode = FloatingObject._make_popMode(models.moveTo)
FloatingObject.pushMode = FloatingObject._make_pushModePings(FloatingObject.moveToMatrix)
FloatingObject.popMode = FloatingObject._make_popModePings(FloatingObject.moveToMatrix)
FloatingObject.swapMode = FloatingObject._make_swapModePings(FloatingObject.moveToMatrix)


-- FloatingObject._setModeKeepPosParent = FloatingObject._make_setMode(FloatingObject.moveToKeepPosParent)
-- FloatingObject.pushModeKeepPosParent = FloatingObject._make_pushMode(FloatingObject.moveToKeepPosParent)
-- FloatingObject.popModeKeepPosParent = FloatingObject._make_popMode(FloatingObject.moveToKeepPosParent)
FloatingObject.pushModeKeepPosParent = FloatingObject._make_pushModePings(FloatingObject.moveToKeepPosParentMatrix)
FloatingObject.popModeKeepPosParent = FloatingObject._make_popModePings(FloatingObject.moveToKeepPosParentMatrix)
FloatingObject.swapModeKeepPosParent = FloatingObject._make_swapModePings(FloatingObject.moveToKeepPosParentMatrix)



function FloatingObject:getParent()
    return self:getModeParent(self.modeStack[#self.modeStack])
end

--- adds an AABB at the part
function FloatingObject:addHitbox(pos,size,name)
    self.hitboxes[name or (#self.hitboxes+1)] = {pos=pos,size=size}
    return self
end

function FloatingObject:addHitboxEdges(pos1,pos2,name)
    self.hitboxes[name or (#self.hitboxes+1)] = {pos=(pos1+pos2)/2,size=(pos2-pos1)}
    return self
end

function Utils.math.edgesToPosScale(pos1,pos2)
    return (pos1+pos2)/2, Utils.math.vectorAbs(pos2-pos1)
end


function Utils.math.vectorAbs(vector)
    return vector:applyFunc(math.abs)
end

---@class Vector
---@field [string] any


---@param matrix Matrix
---@param func fun(vector:Vector,col:number):Vector
function Utils.math.matrix4ApplyFuncVector(matrix,func)
    return matrices.mat4(func(matrix[1],1),func(matrix[2],2),func(matrix[3],3),func(matrix[4],4))
end
---@param matrix Matrix
---@param func fun(vector:Vector,col:number):Vector
function Utils.math.matrix3ApplyFuncVector(matrix,func)
    return matrices.mat3(func(matrix[1].xyz,1),func(matrix[2].xyz,2),func(matrix[3].xyz,3))
end
function Utils.math.matrix4Abs(matrix)
    return Utils.math.matrix4ApplyFuncVector(matrix,Utils.math.vectorAbs)
end

-- works on matrix4 as well, deaugmenting it
function Utils.math.matrix3Abs(matrix)
    return Utils.math.matrix3ApplyFuncVector(matrix,Utils.math.vectorAbs)
end
---@class Matrix
---@field [string] any

---comment
---@param aabb HasPosSize
---@param matrix Matrix
function Utils.math.transformAABB(aabb,matrix)
    return Utils.math.transformAABBAbs(aabb,matrix,Utils.math.matrix3Abs(matrix))
    -- local newpos = matrix:apply(aabb.pos)

end
---@param aabb HasPosSize
---@param abs_matrix Matrix
function Utils.math.transformAABBAbs(aabb,matrix,abs_matrix)
    local newpos = matrix:apply(aabb.pos)
    local newExt = abs_matrix * Utils.math.vectorAbs(aabb.size:copy())
    return {pos = newpos, size = newExt}
end


---@deprecated
function FloatingObject:getAABBs(out)
    local ptwm = self.part:partToWorldMatrix()
    out = out or {}
    for key, cube in pairs(self.hitboxes) do
        local pos = ptwm:apply(cube.pos*PS)
        out[#out+1] = {pos-cube.size/2,pos+cube.size/2, key=key,obj = self}
    end
    return out
end

function FloatingObject:getAABBsO(out)
    -- local ptwm = self.part:partToWorldMatrix()
    out = out or {}
    for key, cube in pairs(self.hitboxes) do
        -- local pos = ptwm:apply(cube.pos*PS)
        out[#out+1] = {(cube.pos-cube.size/2)*PS,(cube.pos+cube.size/2)*PS, key=key,obj = self}
    end
    return out
end
-- log(raycast:aabb(vec(0,0,0), vec(0,0,1), {{-vec(1,1,1),vec(1,1,1)}}))


---@class RaycastOutput
---@field obj FloatingObject
---@field hitboxKey any
---@field globalPos vec3
---@field localPos vec3
---@field distanceSq number
---@field side string?
---@field objectKey? any -- when raycasting a table of multiple FloatingObject, is the key

local debugKey = keybinds:newKeybind("debug", "key.keyboard.j")

---comment
---@param startPos vec3
---@param endPos vec3
---@return RaycastOutput?
function FloatingObject:raycastOriented(startPos,endPos)
    local ptwm = self.part:partToWorldMatrix()
    local wtpm = ptwm:inverted()
    local aabbs = self:getAABBsO()
    local tbl,pos,side,ind = raycast:aabb(wtpm:apply(startPos),wtpm:apply(endPos),aabbs)
    -- if debugKey:isPressed() then
    --     log(tbl,pos,side,ind,wtpm:apply(startPos),startPos)
    --     logTable(aabbs,2)
    --     log(wtpm)
    -- end
    if tbl then
        local globalPos = ptwm:apply(pos)
        local distanceSq = (globalPos-startPos):lengthSquared()
        -- return tbl.obj,tbl.key,globalPos,pos,distanceSq,side
        return {obj = tbl.obj,hitboxKey = tbl.key,globalPos = globalPos,localPos = pos,distanceSq = distanceSq,side = side}

    end
end




---comment
---@param startPos vec3
---@param endPos vec3
---@param objects FloatingObject[]
---@return RaycastOutput?
function FloatingObject.raycastsOriented(startPos,endPos,objects)
    local out
    local distanceSq = (endPos-startPos):lengthSquared()*16
    for key, value in pairs(objects) do
        local out1 = value:raycastOriented(startPos,endPos)
        if out1 and out1.distanceSq < distanceSq then
            distanceSq = out1.distanceSq
            out = out1
            out.objectKey = key
        end
    end
    return out
end


---@deprecated
---comment
---@param startPos vec3
---@param endPos vec3
---@param objects FloatingObject[]
function FloatingObject.raycast(startPos,endPos,objects)
    local aabbs = {}
    for key, value in pairs(objects) do
        value:getAABBs(aabbs)
    end
    local tbl,pos,side,ind = raycast:aabb(startPos,endPos,aabbs)
    if tbl then
        return tbl.obj,tbl.key,pos,side
    end
end


function FloatingObject:createParentInPlace(root,name)
    local p = (root or Positioning.parts.World):newPart(name or "unnamed")
    -- log(p:partToWorldMatrix())
    self.modeParents[name or p] = p
    self:pushModeKeepPosParent(name or p)
end

function FloatingObject:createParent(root,key,name)
    local p = (Utils.ID.from(root) or root or Positioning.parts.World):newPart(name or key)
    -- log(p:partToWorldMatrix())
    self.modeParents[key] = p
    return p
end



function FloatingObject:changePos(change)
    local par = self.part:getParent()
    local d = par:getParent():partToWorldMatrix():invert():applyDir(change)
    -- log(d,par:getPos(),par:getPositionMatrix())
    local pm = par:getPositionMatrix()
    local newPos = pm:getColumn(4).xyz + d
    if self:getID() then
        pings.setFOParentPos(self:getID(),newPos,Utils.ID.get(par))
    else
        par:setMatrix(Utils.setMatrixPos(pm,newPos))
    end
    -- par:setPos(par:getPos() + d)
end

---comment
---@param gizmoID ID<FloatingObject>
---@param pos vec3
---@param parentID ID<ModelPart>|nil
function pings.setFOParentPos(gizmoID,pos,parentID)
    local fo = Utils.ID.from(gizmoID)
    if not fo then error("no id found:" .. gizmoID) end
    --- todo: if these values differ a desync has happened.
    local par = Utils.ID.from(parentID) or fo.part:getParent()
    par:setMatrix(Utils.setMatrixPos(par:getPositionMatrix(),pos))
end



--- todo: abstract raycasting into a superclass