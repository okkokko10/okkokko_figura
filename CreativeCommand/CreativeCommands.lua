
require(".redo.Rect")



Ccom = {} 
Ccom.helper = {}


function Ccom.helper.vectorPrecise(vector)
    if type(vector) =="number" then
        vector = vec(1,1,1) * vector
    end
    return ("%f %f %f"):format(vector:unpack()):gsub(",",".") -- turns , into .
end

function Ccom.helper.vector(vector)
    if type(vector) =="number" then
        vector = vec(1,1,1) * vector
    end
    return ("%d %d %d"):format(vector:unpack())
end
--- note: rounds the coordinates
function Ccom.helper.WEvector(vector)
    if type(vector) =="number" then
        vector = vec(1,1,1) * vector
    end
    return ("%d,%d,%d"):format(vector:unpack())
end

function Ccom.helper.rect(rect)
    return ("%s %s"):format(Ccom.helper.vector(rect[1]),Ccom.helper.vector(rect[2]))
end



function Ccom.helper.WErect(rect)
    return ("%s %s"):format(Ccom.helper.WEvector(rect[1]),Ccom.helper.WEvector(rect[2]))
end

function Ccom.log(...)
    -- return log(...)
end

function Ccom.sendChatCommand(...)
    Ccom.log(...)
    host:sendChatCommand(...)
    return Ccom
end

function Ccom.assemble(rect)
    -- Ccom.log("assemble",tostring(rect))
    Ccom.sendChatCommand(("sable assemble area %s"):format(Ccom.helper.rect(rect)))
end

---comment
---@param rect Rect
---@param block string
---@param mode string?
---@param second string?
function Ccom.fill(rect,block,mode,second)
    -- Ccom.log("fill",tostring(rect),block,mode,second)
    Ccom.sendChatCommand(("fill %s %s"):format(Ccom.helper.rect(rect), table.concat({block,mode,second}," ")))
end
function Ccom.fill_hollow(rect,block)
    return Ccom.fill(rect,block,"hollow")
end

function Ccom.fill_replace(rect,block,replaced)
    return Ccom.fill(rect,block,"replace",replaced)
end
function Ccom.setblock(vector,block,mode,second)
    Ccom.sendChatCommand(("setblock %s %s"):format(Ccom.helper.vector(vector), table.concat({block,mode,second}," ")))
end


function Ccom.setRect(rect)
    Ccom.rect = rect
    Ccom.sendChatCommand(("//pos %s"):format(Ccom.helper.WErect(rect)))
    return rect
end


function Ccom.generate(block,expression,flags)
    Ccom.sendChatCommand(("//g %s %s %s"):format(flags or "-r",block,expression))
end

Ccom.expressions = {}

function Ccom.expressions.manhattanDistance(pos)
    return ("abs(%d-x)+abs(%d-y)+abs(%d-z)"):format(pos:unpack())
end
function Ccom.expressions.manhattanSphere(pos,radius)
    return ("%s==%d"):format(Ccom.expressions.manhattanDistance(pos),radius)
end
function Ccom.expressions.manhattanHalfSphere(pos,radius)
    return ("(%s)*(%d<=y)"):format(Ccom.expressions.manhattanSphere(pos,radius),pos.y)
end


--- at the position, fills a hollow cup at the rect
---@param rect Rect
---@param block string
function Ccom.cup(rect,block)
    rect = rect:positive()
    local bottom = rect:bottom():expand(vec(-1,0,-1))
    Ccom.fill_hollow(rect,block)
    Ccom.fill_replace(bottom,"air",block)
    return rect, bottom
end

--- at the position, fills a hollow cup at the rect
---@param center Vector
---@param radius number
---@param block string
function Ccom.manhattanHalfSphere(center,radius,block)
    local rect = Ccom.setRect(Rect(0,vec(0,radius,0)):expand(vec(radius,0,radius))+center)
    Ccom.generate(block,Ccom.expressions.manhattanHalfSphere(center,radius),"-r")
    return rect
end


function Ccom.cupAssemble(rect,block)
    local rc = Ccom.cup(rect,block)
    Ccom.assemble(rc)
    return rc
end

function Ccom.stackCups(count, size,height,expansion)
    local block = host:getPickBlock()
    if not block then
        log("no block")
        return end
    local pos = block:getPos()
    local id = block:getID()
    count = count or 5
    size = size or 10
    height = height or size
    expansion = expansion or 1
    local startpos = pos
    local top = pos
    for i = 1, count do
        pos = pos + vec(0,height,0)
        local rect = Rect(0,0):expand(vec(size,0,size)) + Rect(0,vec(0,height,0)) +pos
        Ccom.cup(rect,id)
        top = rect.center.x_z + rect.pos2._y_
        Ccom.setblock(top,"air")
        Ccom.assemble(rect)
        size = size + expansion
        height = height + 1
    end

    Ccom.fill(Rect(startpos,top),"packed_ice") 
end

Ccom.color_sequence = {
    "white",
    "light_gray",
    "gray",
    "black",
    "brown",
    "red",
    "orange",
    "yellow",
    "lime",
    "green",
    "teal",
    "light_blue",
    "blue",
    "purple",
    "magenta",
    "pink"
}

function Ccom.stackPyramids(count, size, expansion,space,noassembly)
    local block = host:getPickBlock()
    if not block then
        log("no block")
        return end
    local pos = block:getPos()
    local id = block:getID()
    count = count or 5
    size = size or 10
    -- height = height or size
    expansion = expansion or 1
    local startpos = pos
    local top = pos
    for i = 1, count do
        local blk = string.gsub(id,"white",Ccom.color_sequence[(i - 1) % 16 + 1])
        pos = pos + vec(0,((space or 0) < 0) and (-space) or (size + (space or 0)),0)
        local rect = Ccom.manhattanHalfSphere(pos,size,blk)
        top = rect.center.x_z + rect.pos2._y_
        -- Ccom.setblock(top,"air")
        if not noassembly then Ccom.assemble(rect) end
        size = size + expansion
        -- height = height + 1
    end

    -- Ccom.fill(Rect(startpos,top),"packed_ice") 
end


function Ccom.teleport(vector)
    Ccom.sendChatCommand(("tp %s"):format(Ccom.helper.vectorPrecise(vector)))
end

function Ccom.teleportEyes(vector)
    Ccom.sendChatCommand(("tp %s"):format(Ccom.helper.vectorPrecise(vector - vec(0,player:getEyeHeight(),0))))
end

---comment
---@param partID ID<ModelPart>? to swap with. defaults to Freecam parent
---@param stay boolean? keep the part where it is
function Ccom.playerSwap(partID,stay)
    partID = partID or Freecam.ParentID()
    if AnchorAffix.info.isChildOf(partID,  "Disabled") then
        log("trying to teleport to disabled")
        return
    end
    local m = assert(Conversion.toMatrix(partID))
    local p = m:apply()
    local pp = Utils.entity.entityEyePos(player,client.getFrameTime())
    -- local pp = player:getPos(client.getFrameTime())

    -- log(p)
    Ccom.teleportEyes(p)

    if stay then return end

    --- pp -> world to part = pp in partID's coordinates
    local dp = m:inverted():apply(pp)
    local nm = m * matrices.translate4(dp)
    --- m * matrices.translate4(m:invert():apply(pp))
    AnchorAffix.complex.affixInPlace(partID,nil,nm)


end

function Ccom.players()
    logTable(world.getPlayers())
end

function Ccom.attribute_range(r)
    Ccom.sendChatCommand(("attribute @s minecraft:player.block_interaction_range modifier add range %d add_value"):format(r or 100))
end

--#region Coroutined

local Coroutine = require"Coroutine"

Ccom.IO = {}


Ccom.IO.Types = {}


local intercept_sable_info_trigger_string = "$Found (%S)* sub%-levels%:^"

---comment
---@param con CoroutineConstructor
---@param count integer
function Ccom.IO.read_translate_with(con,count,match)
    for i = 1, count do
        con:add(
        ---@param raw string
        ---@param text string
        ---@param tbl table
        function (raw,text,tbl)
            if match then
                assert(string.find(tbl.translate,match))
            end
            Coroutine.vars[tbl.translate] = tbl.with
        end)
    end
    return con
end

--- the keys are formatted as string.find(tbl.translate,pattern)
---@param con CoroutineConstructor
---@param count integer
---@param pattern string
function Ccom.IO.read_translate_with_pattern(con,count,pattern)

    for i = 1, count do
        con:add(
        ---@param raw string
        ---@param text string
        ---@param tbl table
        function (raw,text,tbl)
            Coroutine.vars[assert(string.find(tbl.translate,pattern),tbl.translate .. " " .. pattern)] = tbl.with
            return table.unpack(tbl.with)
        end)
    end
    return con
end

--- returns nil if the pattern is no found.
---@param con CoroutineConstructor
---@param pattern string
---@param plain boolean?
function Ccom.IO.read_translate_with_matching_pattern(con, pattern,plain)
    con:add(
    ---@param raw string
    ---@param text string
    ---@param tbl table
    function (raw,text,tbl)
        -- if not tbl.translate then
        --     log("translate not present",raw,text,tbl)
        -- end
        if tbl.translate and string.find(tbl.translate,pattern,nil,plain) then
            return table.unpack(tbl.with)
        end
    end)
    
    return con
end

-- ---comment
-- ---@param translates string[]
-- function Ccom.IO.sable_info_element_like(translates)
--     local out = Coroutine.constructor()
--     for index, translate in ipairs(translates) do
--         out:add(
--         ---@param raw string
--         ---@param text string
--         ---@param tbl table
--         function (raw,text,tbl)
--             if tbl.translate == translate then

--             end
--         end)
--     end
-- end

    -- "commands.sable.info.name" 
    -- "commands.sable.info.position"
    -- "commands.sable.info.orientation"
    -- "commands.sable.info.mass"
    -- "commands.sable.info.linear_velocity"
    -- "commands.sable.info.angular_velocity"

local Intercept_sable_info_single = Coroutine.constructor()
Ccom.IO.read_translate_with(Intercept_sable_info_single,6,"commands%.sable%.info%.(.*)")
:pipe():add(function (...)
    logTable(Coroutine.vars,3)
end)



local Intercept_sable_info = Coroutine.constructor()
Ccom.IO.read_translate_with_matching_pattern(Intercept_sable_info,"commands.sable.info.count",true)

:pipe()
:rep(Intercept_sable_info_single)
:pipe()
-- :add(function (...)
--     log("finished sable info coroutine",...)
-- end)

Ccom.IO.Types.Intercept_sable_info = Intercept_sable_info






---checked for all messages when there is an interception active
-- function Intercept_sable_info.trigger(raw,text)
--     local count = string.find(text,Intercept_sable_info.trigger_string)
--     if count then


--     end
    

-- end


function Ccom.IO.await()
    
end


local texts = ""

Ccom.IO.listen_next = false
Ccom.IO.copying = false

-- Utils.parts.child(models,"gui","GUI")
local gui = models:newPart("Ccom_gui","GUI")
local center_text = gui:newText("center_text"):setPos(client.getScaledWindowSize().x__/(-2)):setWidth(client.getScaledWindowSize().x/2)


function Ccom.IO.write_text_center(text)
    center_text:setText(text or "")
end


local thread = Intercept_sable_info:instance()



--- raw is
function Ccom.IO.chat_receive_message(raw,text)
    -- host:setActionbar(raw)

    if Ccom.IO.copying then
        texts = texts .. "\1" .. text .. "\n\2" .. (raw) .. "\n"
    end
    -- Ccom.IO.write_text_center(toJson(raw))
    if Ccom.IO.listen_next then
        -- log("CHAT:",raw,text)
        logTable(parseJson(text),4)
        Ccom.IO.listen_next = false
    end
    
    local tbl = parseJson(text)

    local res, a = thread:resume(raw,text,tbl)
    if not res then
        thread = Intercept_sable_info:instance()
    end

    -- return toJson(text)
end
function Ccom.IO.copy_last()
    -- host:setActionbar(raw)
    host:setClipboard(texts)
    texts = ""
end

-- events.CHAT_RECEIVE_MESSAGE:register(Ccom.IO.chat_receive_message)

--- WE
function Ccom.Lookat()
    local block,pos = host:getPickBlock()
    return Ccom.helper.WEvector(pos)
end
--- vanilla
function Ccom.lookat()
    local block,pos = host:getPickBlock()
    return Ccom.helper.vector(pos)
end

Ccom.macros = {}

Ccom.macros.command_starter = "%!%%"

Ccom.macros.recording = nil

Ccom.macros.macros = {}


Ccom.macros.functions = {}

function Ccom.macros.functions.DEF(rest)
    if Ccom.macros.functions[rest] then
        log("cannot overload ".. rest)
    end
    local out = {}
    Ccom.macros.recording = out
    Ccom.macros.macros[rest] = out
end

function Ccom.macros.functions.END(rest)
    Ccom.macros.recording = nil
end

function Ccom.macros.functions.UNDO(rest)
    if Ccom.macros.recording then
        Ccom.macros.recording[#Ccom.macros.recording] = nil
    end
end
function Ccom.macros.functions.VIEW(rest)
    logTable(Ccom.macros.macros[rest] or Ccom.macros.recording or Ccom.macros.macros,3)
end

function Ccom.macros.functions.SAVE(rest)
    config:setName("macros"):save("macros",Ccom.macros.macros)
    log("saved macros")
end
function Ccom.macros.functions.LOAD(rest)
    Ccom.macros.macros = config:setName("macros"):load("macros") or {}
end
Ccom.macros.functions.LOAD()

function Ccom.macros.record(message)
    
    if Ccom.macros.recording then
        table.insert(Ccom.macros.recording,message)
    end
end

function Ccom.macros.execute(macro)
    if not macro then
        return
    end
    for index, value in ipairs(macro) do
        local com = Ccom.substitute_message(value,true)
        if com then
            Ccom.sendChatCommand(com)
        end
    end
end

---comment
---@param message string
function Ccom.macros.macro_send_message(message)
    if type(message) ~= "string" then return message end

    local word,rest = message:match("^"..Ccom.macros.command_starter .."%s*(%S*)(.*)")
    if word then
        local f = Ccom.macros.functions[word]
        if f then
            local r,r2 = rest:match("%s*(%S*)(.*)")
            return f(r,r2)
        else
            local macro = Ccom.macros.macros[word]
            if macro then
                -- putting substitutable values after the macro name is possible
                local subst = Ccom.substitute_message(rest,true)
                Ccom.macros.execute(macro)

            end
        end
    end
    -- should record running macros.macros but not macros.functions
    Ccom.macros.record(message)


    return message


end

---fixes an issue with `loadstring`
---@param text string
---@param chunkname? string
---@param env? table
---@return function?
---@return string? error_message
---@nodiscard
function Loadstring(text, chunkname, env)
    return loadstring(text.." ",chunkname,env)
end


---comment
---@param message string
function Ccom.substitute_message(message,fake)
    if type(message) ~= "string" then return message end
    local function loo(a)
        return Loadstring("return "..a,nil)
    end
    -- local q = _ENV

    -- local modified = string.gsub(message,"%$(%b{})", function (b)
    --     local a = string.sub(b,2,-2)
    local modified = string.gsub(message,"!#(.-)#!", function (a)
        -- local a = string.sub(b,2,-2)
        local w,dots,res = string.match(a,"^(.-)([%.%:]+)([%w_]*)$")
        if res == "" then
            a = w
        else
            -- log("res:",w,dots,res)
        end
        local c, q = loo(a)
        if fake and w and not c and string.find(q,"function arguments expected") then
            c,q = loo(w)
        end

        if c then
            local r, s = pcall(c)
            if w then
                return logTable(s,string.len(dots or " "),true)
            end
            
            if r or true then
                return tostring(s)
            end
        else
            return tostring(q)
        end

    end)
    -- log("last message:",host:getChatMessage(1))
    if not fake then
        host:appendChatHistory(message)
    end
    return modified
end




events.CHAT_SEND_MESSAGE:register(Ccom.macros.macro_send_message)
events.CHAT_SEND_MESSAGE:register(Ccom.substitute_message)

local prev_chat_text = nil

function Ccom.chatTextPreview (force)
    local tx = host:getChatText()
    if (force == "force") or prev_chat_text ~=tx then
        prev_chat_text = tx
        if not tx then
            Ccom.IO.write_text_center(nil)
            return
        end
        
        local modif = Ccom.substitute_message(tx,true)
        Ccom.IO.write_text_center(modif)
        

    end
    -- if not tx then return end
    -- local modif = Ccom.substitute_message(tx,true)

    -- local chng = false
    -- local ntx = string.gsub(tx,"#([^#]*)#",function (b)
    --     chng = true
    --     return "("..b..")"
    -- end)
    -- if chng then
    --     host:setChatText(ntx)
    -- end

end

local evaluate_key = keybinds:newKeybind("evaluate open chat","key.keyboard.grave.accent",true)

function evaluate_key.press(mod,self)
    Ccom.chatTextPreview("force")
end



-- events.world_render:register(Ccom.chatTextPreview)




function Ccom.awaitChat(filter,callback)


    

end





--#region motorcontrol


Ccom.motor = {}

function Ccom.motor.getData(pos,path)
    local d = world.getBlockState(pos)
    local q = d:getEntityData()
    if q then
        return Utils.table.getNest(q,path)
    end
end
function Ccom.motor.setMotor(pos,facing,speed)
    
end


function Ccom.motor.run()
    

end


--#endregion