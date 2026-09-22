


local debugpart = models:newPart("hitdebug","WORLD")

local dtext = debugpart:newPart("billboard","BILLBOARD"):newText("text")
local dbox = models:newPart("hitboxx","WORLD"):newPart("hb")
local dit = dbox:newItem("a"):setItem("red_stained_glass")

Utils.ID.field.dbox = dbox



---comment
---@param modelPart ModelPart
---@param text unknown
---@param origin Vector
---@param direction Vector
local function text_raycast(modelPart,text,origin,direction,height)
    
    local m = modelPart:partToWorldMatrix() * text:getPositionMatrix()
    local cm = Conversion.ComposedMatrix(modelPart,text:getPositionMatrix())

    ---@type string?
    local tx = text:getText()
    if not tx then return end
    height = height or 10
    local rect = Rect(vec(-1000,-1000*height,0),vec(1000,0,1))
    local hi = Hitbox:create(cm,rect)

    local q = Conversion.toMatrix(cm)
    dbox:setMatrix(q*PS)
    -- log(q)
    -- rect:setCenteredItemTo(dit)



    local epos = origin + direction*1000
    local ou = (hi:raycastOriented(origin,epos,1))
    if ou then
        -- log(ou)
        debugpart:setPos(PS*ou.globalPos)
        -- local selectedText = strings[math.ceil(ou.localPos.y/(-10))]
        dtext:setText(tostring(math.ceil(ou.localPos.y/(-10))).." "..tostring(ou.localPos/vec(1,-10,1)))
        Invoke:setVariable("!SelectedRow",math.ceil(ou.localPos.y/(-10)))
    else
        Invoke:setVariable("!SelectedRow",nil)
    end



end


if host:isHost() then
    
events.TICK:register(function (dir)
    local part = Utils.ID.field.ChatText.billboard
    local text = part:getTask("text")

    local origin = client.getCameraPos()
    local direction = client.getCameraDir()

    local p = text_raycast(part,text,origin,direction)

end)

end