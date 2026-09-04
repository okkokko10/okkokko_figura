

DrawLine = {}


---changes part into a line. in pixel scale, draw a line between two points with the width config.width
---@param part ModelPart
---@param from Vector
---@param to Vector
---@param config table?
---@return ModelPart
function DrawLine.line(part,from,to,config)

    config = config or {}
    
    
    local difference = to - from
    local midpoint = (to + from) / 2
    -- local toCamera = (client.getCameraPos() - midpoint):normalize()
    local toCamera = vec(0,1,0)
    local orthogonalToCam = difference:crossed(toCamera):normalize()
    if orthogonalToCam:length() == 0 then
        toCamera = vec(1,0,0)
        orthogonalToCam = difference:crossed(toCamera):normalize()
    end


    part:setMatrix(matrices.mat4(
        -difference.xyz_,orthogonalToCam:augmented(0),(toCamera):augmented(0),((from)):augmented(1)
    ))
    

    -- local rep = config.rep or 5
    local startY = 6 or config.charStartY
    local height = 1 or config.charHeight
    local widthChar = 1 or config.charWidth
    local width = (config.width or 1)
    
    -- local text =  '[{"text"="'..("--"):rep(rep)..'", color="#0088FF"}]'
    -- local text =  ('[{"text"="%s", color="%s"}]'):format((config.line or "--"):rep(rep),config.color or "#0088FF")
    local text =  ('[{"text"="%s", color="%s"}]'):format((config.char or "."),config.color or "#0088FF")
    -- local text2 = '[{"text"="'..("=="):rep(rep)..'", color="#FF8800"}]'
    local function wf(textTask)
        return textTask:setSeeThrough(config.seeThrough)
            :setText(text)
            :setAlignment("LEFT")
            :setScale(1/widthChar,width,1)
            :setOpacity(config.opacity or 1)
        
    end

    --- a text task always has 1 pixel of space between symbols.

    wf(part:newText("a"))
            :setPos(0, (startY + height/2)*width,0)
    wf(part:newText("b"):setRot(180,0,0))
            :setPos(0,-(startY +height/2)*width,0)

    -- part:newText("b"):setSeeThrough(true):setText(text2):setAlignment("RIGHT"):setWidth(16*rep):setScale(1/rep,1,1)
    
    --:setPos(from*PS)
    -- part:newText("b"):setSeeThrough(true):setPos(to*PS)
    -- log(from,to)
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


return DrawLine