require"./Conversion"


require"utils"





AnchorAffix = {}

AnchorAffix.direct = {}


---comment
---@param partID ID<ModelPart>
---@param parentID? ID<ModelPart>
---@param matrix? ConvertsToMatrix
---@param pos? Vector
---@param rot? Vector
function AnchorAffix.direct.part_alter(partID,parentID,matrix,pos,rot)
    
    local part = Utils.ID.from(partID)
    if not part then
        return host:isHost() and log("no such part: " .. partID)
    end
    local parent = parentID and Utils.ID.from(parentID)
    if parent then
        if parent:isChildOf(part) or parent == part then
            if host:isHost() then
                log("error, setting as own ancestor")
            end
        else
            part:moveTo(parent)
        end
    end
    matrix = Conversion.toMatrix(matrix)
    if matrix then
        part:setMatrix(matrix)
    end
    if pos then
        part:setPos(pos)
    end
    if rot then
        part:setRot(rot)
    end
end


---comment
---@param partID ID<ModelPart>
---@param parentID? ID<ModelPart>
---@param matrix? ConvertsToMatrix
---@param pos? Vector
---@param rot? Vector
function pings.part_alter(partID,parentID,matrix,pos,rot)
    AnchorAffix.direct.part_alter(partID,parentID,matrix,pos,rot)
end



AnchorAffix.complex = {}

--- if target is given, instead sets world matrix to that while setting parent.
--- if parent is nil, sets world matrix to target without setting parent.
---@param partID ID<ModelPart>
---@param parentID? ID<ModelPart> -- new parent
---@param target? ConvertsToMatrix -- new world matrix
function AnchorAffix.complex.affixInPlace(partID, parentID, target,noPing)
    local part = Utils.ID.from(partID) or error("no part: ".. (partID or "nil"))
    if parentID then
        local mat = Conversion.toMatrix(parentID):invert() * Conversion.toMatrix(target or part)
        if noPing then
            AnchorAffix.direct.part_alter(partID,parentID,mat)
        else
            pings.part_alter(partID,parentID,mat)
        end
    else
        local mat = Conversion.toMatrix(part:getParent()):invert() * Conversion.toMatrix(target or partID)
        if noPing then
            AnchorAffix.direct.part_alter(partID,parentID,mat)
        else
            pings.part_alter(partID,parentID,mat)
        end
    end
end

AnchorAffix.info = {}

---@param partID ID<ModelPart>
---@param parentID ID<ModelPart> -- new parent
---@return boolean|nil
function AnchorAffix.info.isChildOf(partID, parentID)
    local part = Utils.ID.from(partID)
    local parent = Utils.ID.from(parentID)
    if part and parent then
        return part:isChildOf(parent) or partID == parentID
    else
        return nil
    end
end
---@param partID ID<ModelPart>
---@return ID<ModelPart>
function AnchorAffix.info.getParentID(partID)
    local p = Utils.ID.from(partID)
    return Utils.ID.get(p and p:getParent())
end
return AnchorAffix