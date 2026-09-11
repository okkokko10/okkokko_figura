

DrawLine = {}


---@class DrawLineConfig
---@field char string?
---@field charHeight number?
---@field charStartY number?
---@field charWidth number?
---@field color string?
---@field opacity number?
---@field seeThrough boolean?
---@field width number?


    --- goes rightmost in the matrix multiplication. 
    --- transforms the text to occupy the rectangle [0, 1] × [-.5, .5]
    --- from [0,widthChar] × [startY, startY + height]
local function characterToLineMatrix(widthChar,height,startY,lineWidth,z)
    ---     -.5 = a * startY + b
    ---     .5 = a * (startY + height) + b
    --- y' = (1/height) * y + (-.5 - startY/height)
    return matrices.mat4(
        vec(1/widthChar,0,0,0),
        vec(0,(lineWidth/height),0,0),
        vec(0,0,z,0),
        vec(0,lineWidth*(-.5 - startY/height),0,1)
    )
end

--- should return a matrix where the first column is v, and is orthogonal
--- todo: make work
---@param v Vector
---@param o Vector
---@return Matrix<4>
local function pointingMatrix(v,o)
    local toCamera = vec(0,1,0)
    local orthogonalToCam = v:crossed(toCamera):normalize()
    if orthogonalToCam:length() == 0 then
        toCamera = vec(1,0,0)
        orthogonalToCam = v:crossed(toCamera):normalize()
    end

    return matrices.mat4(
        v:augmented(0),
        orthogonalToCam:augmented(0),
        (toCamera):augmented(0),
        o:augmented(1)
        )
end

---changes part into a line. in pixel scale, draw a line between two points with the width config.width
---@param part ModelPart
---@param from Vector
---@param to Vector
---@param config DrawLineConfig?
---@return ModelPart
function DrawLine.line(part,from,to,config)

    config = config or {}
    
    
    local difference = to - from

    local mat = pointingMatrix(-difference,from)
    -- part:setMatrix(mat)
    

    -- local rep = config.rep or 5
    local startY = 6 or config.charStartY
    local height = 1 or config.charHeight
    local widthChar = 1 or config.charWidth
    local width = (config.width or 1)

    --- todo: can you swizzle matrices? 
    ---     add thickness to lines with cross. 
    
    --- goes rightmost in the matrix multiplication. 
    local characterToLine1 = characterToLineMatrix(widthChar,height,startY,width,1)
    local characterToLine2 = characterToLineMatrix(widthChar,height,startY,width,-1)
    
    local text = toJson{text = config.char or ".", color = config.color}

    local function wf(textTask)
        return textTask:setSeeThrough(config.seeThrough)
            :setText(text)
            :setAlignment("LEFT")
            :setOpacity(config.opacity or 1)
        
    end

    --- a text task always has 1 pixel of space between symbols.

    wf(part:newText("a")):setMatrix(mat*characterToLine1)
    wf(part:newText("b")):setMatrix(mat*characterToLine2)
    return part
    
end

function DrawLine.test(part)
    
    --- testing DrawLine
    for index, value in ipairs({
        {1,"red","|."},
        {1/2,"green","ab"},
        {1/4,"blue"},
        {1/8,"red"},
        {1/16,"yellow"},
    }) do
        
        DrawLine.line(part:newPart("linetest"),
            vec(0,4,0)*PS,
            vec(0,4,1)*PS,
            {
                width = value[1],
                color = value[2],
                -- line =  "."
            }
        )
    end
    part:newItem("lineitem"):setItem("glass"):setPos(vec(0,5,0)*PS)

    -- local w = {}
    -- for i = 0, 255 do
    --     w[i]=i
    -- end
    -- local allChars = string.char(table.unpack(w))
    part:newText("testChars"):setText("██▓▓▒▒──."):setPos(15*PS,10*PS,0)

    
end

---todo: draws a colored cube in the same fashion
---@param part ModelPart
---@param config DrawLineConfig
function DrawLine.Cube(part,config)
    
end



return DrawLine