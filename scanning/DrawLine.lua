

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
---@field name string?


    --- goes rightmost in the matrix multiplication. 
    --- transforms the text to occupy the rectangle [0, 1] × [-.5, .5]
    --- from [0,widthChar] × [startY, startY + height]
local function characterToLineMatrix(widthChar,height,startY,lineWidth,z)
    ---     -.5 = a * startY + b
    ---     .5 = a * (startY + height) + b
    --- y' = (1/height) * y + (-.5 - startY/height)
    

    
    local from = Rect.fromIntervals({0,widthChar},{-startY,-startY-height},{0,1})
    local dest = Rect.fromIntervals({0,1},{-.5*lineWidth*z,.5*lineWidth*z},{0,1})
    -- local dest = Rect.fromIntervals({0,1},{0,1},{0,1})
    return from:matrixInto(dest)
    -- return matrices.mat4(
    --     vec(1/widthChar,0,0,0),
    --     vec(0,(lineWidth/height),0,0),
    --     vec(0,0,z,0),
    --     vec(0,lineWidth*(-.5 - startY/height),0,1)
    -- ):transpose()
end

--- should return a matrix where the first column is v, and is orthogonal
--- todo: make work
---@param v Vector
---@param o Vector
---@return Matrix<4>
local function pointingMatrix(v,o)
    local toCamera = vec(0,1,0)
    local orthogonalToCam = v:crossed(toCamera)
    if orthogonalToCam:length() == 0 then
        toCamera = vec(1,0,0)
        orthogonalToCam = v:crossed(toCamera)
    end

    return matrices.mat4(
        v:augmented(0),
        orthogonalToCam:normalize():augmented(0),
        toCamera:augmented(0),
        o:augmented(1)
        )
end


function DrawLine.line_texts(part,config)
    
    local text = toJson{text = config.char or ".", color = config.color}
    local nm = "line" .. math.random()
    local function wf(id)
        return part:newText(nm..id):setSeeThrough(config.seeThrough)
            :setText(text)
            :setAlignment("LEFT")
            :setOpacity(config.opacity or 1)
    end
    return {wf("a"),wf("b"),wf("c"),wf("d")}
end

function DrawLine.line_matrices(config)
    
    local startY = 6 or config.charStartY
    local height = 1 or config.charHeight
    local widthChar = 1 or config.charWidth
    local width = (config.width or 1)

    --- goes rightmost in the matrix multiplication. 
    local characterToLine1 = characterToLineMatrix(widthChar,height,startY,width,1)
    local characterToLine2 = characterToLineMatrix(widthChar,height,startY,width,-1)
    local rotMatrix = matrices.rotation4(90,0,0)
    local characterToLine3 = rotMatrix*characterToLine1
    local characterToLine4 = rotMatrix*characterToLine2
    return {characterToLine1,characterToLine2,characterToLine3,characterToLine4}
end

function DrawLine.line_apply_matrices(texts,matrices,mat)
    for i = 1, 4 do
        texts[i]:setMatrix(mat*matrices[i])
    end
end


---adds a line to part. in pixel scale, draw a line between two points with the width config.width
---@param part ModelPart
---@param from Vector
---@param to Vector
---@param config DrawLineConfig?
---@return ModelPart
---@return table
---@return Matrix[]
function DrawLine.line(part,from,to,config)
    config = config or {}
    
    local mat = pointingMatrix(from-to,from)
    -- part:setMatrix(mat)
    

    -- local rep = config.rep or 5
    local startY = 6 or config.charStartY
    local height = 1 or config.charHeight
    local widthChar = 1 or config.charWidth
    local width = (config.width or 1)

    --- todo: can you swizzle matrices? 
    ---     add thickness to lines with cross. 
    
    
    local text = toJson{text = config.char or ".", color = config.color}
    local nm = tostring(from)..tostring(to) .. math.random()

    local function wf(id)
        return part:newText(nm..id):setSeeThrough(config.seeThrough)
            :setText(text)
            :setAlignment("LEFT")
            :setOpacity(config.opacity or 1)
        
    end

    --- a text task always has 1 pixel of space between symbols.

    --- goes rightmost in the matrix multiplication. 
    local characterToLine1 = characterToLineMatrix(widthChar,height,startY,width,1)
    local characterToLine2 = characterToLineMatrix(widthChar,height,startY,width,-1)
    local rotMatrix = matrices.rotation4(90,0,0)
    local characterToLine3 = rotMatrix*characterToLine1
    local characterToLine4 = rotMatrix*characterToLine2

    if config.debugbase then
        wf("debug"):setMatrix(characterToLine1) -- debugging
    end

    
    return part, {wf("a"):setMatrix(mat*characterToLine1),
        wf("b"):setMatrix(mat*characterToLine2),
        wf("c"):setMatrix(mat*characterToLine3),
        wf("d"):setMatrix(mat*characterToLine4)}, {characterToLine1,characterToLine2,characterToLine3,characterToLine4}
    
end

function DrawLine.test(part)
    local prt = part:newPart("testLine"):setPos(0,0,-PS)
    --- testing DrawLine
    for index, value in ipairs({
        {1,"red","|."},
        {1/2,"green","ab"},
        {1/4,"blue"},
        {1/8,"red"},
        {1/16,"yellow"},
    }) do
        for i2, dir in ipairs(
            {
                vec(0,0,1),
                vec(0,1,0),
                vec(1,0,0),
                vec(0,1,1),
                vec(1,1,1)
            }
        ) do 
            DrawLine.line(prt:newPart("linetest"):setPos(0,0,0),
                vec(0,0,0),
                dir*PS,
                {
                    width = value[1],
                    color = value[2],
                    seeThrough = true,
                    opacity = 0.5,
                    char =  ".",
                    debugbase = true
                }
            )
        end
        
    end
    prt:newBlock("lineitem"):setBlock("grass_block") 
    -- prt:newText("bas"):setText(".▒")
    -- prt:newText("bas2"):setText(toJson({text=".",color="#000000"})):setPos(0,1,0)
    -- prt:newText("bas3"):setText(toJson({text=".",color="#00FF00"})):setPos(1,0,0)


    -- local w = {}
    -- for i = 0, 255 do
    --     w[i]=i
    -- end
    -- local allChars = string.char(table.unpack(w))
    -- part:newText("testChars"):setText("██▓▓▒▒──."):setPos(15*PS,10*PS,0)

    
end

function Positioning.functions.lineTo(target)
    return function(delta, ctx, part)
        local p = part:getParent():partToWorldMatrix():invert():apply(target:partToWorldMatrix():apply())
        part:setMatrix(pointingMatrix(p,vec3()))
    end
end

---returns a new ModelPart where (0,0,0) is the parent's origin and (1,0,0) is the target's origin.
---@param parent ModelPart
---@param target ModelPart
---@param name string?
---@return ModelPart
function Positioning.make.lineTo(parent,target,name)
    return parent:newPart(name or ("lineTo"..tostring(math.random())))
            :setPreRender(Positioning.functions.lineTo(target))
end

---returns a new child that draws a line to target. safe to move to another parent. Should be safe to duplicate.
---@param part ModelPart
---@param target ModelPart
---@param config DrawLineConfig?
function DrawLine.lineBetween(part,target,config)

    local p = Positioning.make.lineTo(part,target,config and config.name)
    DrawLine.line(p,vec3(),vec(1,0.01,-0.02),config)
    return p
end


Invoke:registerByValue("DrawLine",function (self, rest, input)
    if self:restContains(rest,"test") then
        DrawLine.test(input)
    end
end)

function Utils.ID.inits.Freecam(f)
function Utils.ID.inits.Disabled(d)
    ---@type ModelPart
    Utils.ID.field.SpareLineEnd = Utils.ID.field.Freecam:newPart("SpareLineEnd")
    ---@type ModelPart
    Utils.ID.field.SpareLineStart = Utils.ID.field.Disabled:newPart("SpareLineStart")
    ---@type ModelPart
    Utils.ID.field.SpareLine = DrawLine.lineBetween(Utils.ID.field.SpareLineStart,Utils.ID.field.SpareLineEnd,
        {
            seeThrough=true,
            color="#"..vectors.rgbToHex(0.1,1,0.5),
        })
        
    Grabbing.addSelectableGenerate("SpareLineStart")
    Grabbing.addSelectableGenerate("SpareLineEnd")
end
end





---todo: draws a colored cube in the same fashion
---@param part ModelPart
---@param config DrawLineConfig
function DrawLine.Cube(part,config)
    
end





return DrawLine