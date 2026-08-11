
require"utils"


Conversion = {}





---@package
---@class ComposedMatrix
Conversion._ComposedMatrix = {__type = "ComposedMatrix"}
Conversion._InvertedMatrix = {__type = "InvertedMatrix"}

---lazily composes matrices
---@param left ConvertsToMatrix
---@param right ConvertsToMatrix
---@return ComposedMatrix
function Conversion.ComposedMatrix(left,right)
    return setmetatable({left,right},Conversion._ComposedMatrix)
end

---lazily inverts matrix
---@param matrix ConvertsToMatrix
---@return ComposedMatrix
function Conversion.InvertedMatrix(matrix)
    return setmetatable({matrix},Conversion._InvertedMatrix)
end




---@alias ConvertsToMatrix Matrix|Vector|ModelPart|ID<ModelPart>|function|nil|boolean|ComposedMatrix|{matrix:ConvertsToMatrix}

---@package 
---@generic T: ConvertsToMatrix|boolean
---@type { [Type<T>] : fun(value:T,...) : Matrix}
Conversion._toMatrix = {
    Matrix3 = function (value) return value:augmented() end,
    Matrix4 = function (value) return value end,
    Vector3 = function (value) return matrices.mat4():translate(value) end,
    ModelPart = function (part,...) return part:partToWorldMatrix() end,
    string =  function (id,...) return Conversion.toMatrix(Utils.ID.from(id),...) end,
    ["nil"] = function (n,...)
        if (select("#",...)>0) then
            return Conversion.toMatrix(...) 
        else return nil end end, --- ... are fallback arguments
    ["function"] = function (f,...) return Conversion.toMatrix(f(...),...) end,
    none = function (other,...) 
        if other.matrix then
            return Conversion.toMatrix(other.matrix,...)
        end
        return Conversion.toMatrix(...) end,
    boolean = function (b,...) if b then return matrices.mat4() else return nil end end,
    ComposedMatrix = function (value) return Conversion.toMatrix(value[1],true) * Conversion.toMatrix(value[2],true) end,
    InvertedMatrix = function (value) return Conversion.toMatrix(value[1],true):inverted() end,
    -- PlayerAPI = function (entity) return Conversion.toMatrix(value[1],true):inverted() end
}

---@generic T
---@class Type<T>: string


if false then
    ---@generic S
    ---@overload fun(s:S): Type<S>
    type = type
end


--- if the first argument cannot be converted to a matrix, the next argument is tried. unless the argument evaluates to `false`, in which case it returns nil
--- if the arguments run out, returns the identity matrix
---@param value ConvertsToMatrix|boolean
---@param ... any -- fallback arguments
---@return Matrix
function Conversion.toMatrix(value,...)
    return (Conversion._toMatrix[type(value)] or Conversion._toMatrix["none"])(value,...)
end



return Conversion