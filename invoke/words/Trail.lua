require"invoke.Invoke"


local Trail = {}


Trail._lastPos = Utils.table.kmode()
Trail._lastDeriv = Utils.table.kmode()


---comment
---@param trail_key any
---@param vertex Vector
---@param parent ModelPart<"World">
---@param config DrawLineConfig?
---@param speed Vector?
---@param sconfig DrawLineConfig?
---@param acceleration_config DrawLineConfig? -- if present, draws acceleration.
function Trail.append(trail_key,vertex,parent,min_motion,config,speed,sconfig,acceleration_config)
    vertex = Utils.Sublevel.sableSublevelToWorld(vertex)
    local last_pos = Trail._lastPos[trail_key]
    if not last_pos then
        Trail._lastPos[trail_key] = vertex
        Trail._lastDeriv[trail_key] = speed
        return
    end
    if vertex then
        min_motion = min_motion or 0.00001
        local last_speed = Trail._lastDeriv[trail_key]
        local different = (vertex-last_pos):length() > min_motion
        local acceleration = speed and last_speed and (speed-last_speed)
        local acceleration_positive = acceleration and (acceleration):length() > min_motion
        if speed and (different or (acceleration_positive ~= false)) then
            
            -- log(vertex,derivative)
            DrawLine.line(parent,vertex*PS,(vertex+speed)*PS,sconfig)
            if acceleration_config and acceleration_positive then -- maybe this should be in the previous end?
            DrawLine.line(parent,(vertex+speed)*PS,(vertex+speed+acceleration)*PS,acceleration_config)
                
            end

        end
        
        Trail._lastDeriv[trail_key] = speed

        if not different then
            return
        end

        DrawLine.line(parent,last_pos*PS,vertex*PS,config)
    end
    Trail._lastPos[trail_key] = vertex
    Trail._lastDeriv[trail_key] = speed
end
function Trail.clear(trail,parent)
    Trail._lastPos[trail] = nil
    Trail._lastDeriv[trail] = nil
    if parent then
        parent:remove()
    end
end


---todo: allow the trail to be parented on something
--- updates a trail for this ModelPart
--- note: uses "World" ParentType, which is not viewable from a skull.
Invoke:registerWithArgs("Trail",{"parent?","position?","color?","derivative?"},function (self, rest, input)

    
    local min_motion = 0.01
    assert((not input.position) or type(input.position) == "Vector3")
    local position = input.position
    
    local parent
    if type(input.parent) == "ModelPart" then
        -- parent = Utils.parts.child(input.parent,"Trail","World")
        parent = Positioning.make.WorldChild(input.parent,"Trail")
        if input.position == nil then
            position = input.parent:partToWorldMatrix()
        end
    else
        if input.position == nil then
            return -- no position to place in.
        end
        parent = Utils.parts.child(models,"GlobalTrail","World")

    end
    local trailID = input.parent or parent


    if rest == "clear" then
        Trail.clear(trailID,parent)
        return
    end

    local config = {color = input.color,opacity=0.5}

    Trail.append(trailID,position,parent,min_motion,config,input.derivative,{color="#0000FF"})
    
end)

--- todo: ask how to get entity nbt for :newEntity():setNbt( )
--- todo: trail of the entity itself



TrailArrow = models:newPart("TrailArrow","Arrow")
:setPostRender(function (delta, ctx, part)
    -- log(delta,ctx,part,part:partToWorldMatrix())
    
end)

TrailArrow:newItem("blk"):setItem("glass"):setScale(1/8,1/8,1):setPos(0,0,8)
-- local spd = TrailArrow:newPart("bb","Billboard"):newText("spd"):setText(""):setSeeThrough(true):setScale(1/4)
local spd = TrailArrow:newPart("bb"):setRot(0,90,0):setPos(-1,1,0):newText("spd"):setText(""):setScale(1/4)--:setSeeThrough(true)
TrailArrow:newPart("cb"):setRot(0,180,0):setPos(0,0,16):addChild(TrailArrow.bb)

--- todo: matrix for the sides of a rect

Positioning.make.WorldChild(TrailArrow,"Trail")
TrailArrow:newPart("WTrail","World")
-- TrailArrow:setPreRender(function (delta, ctx, part)
    

-- end)


--- todo: if an arrow hasn't appeared in a frame, remove it.

local function arrow_render(delta, arrow)
    local uuid = arrow:getUUID()
    local pos = arrow:getPos()
    local nbt = arrow:getNbt()
    local motion =nbt.Motion and vec(table.unpack(nbt.Motion))
    spd:setText(("%.2f"):format(motion:length()))
    
    if Utils.tick.first_frame_for(uuid) then


        local part = Utils.parts.child(TrailArrow.WTrail,uuid)
        Utils.tick.register_gc(uuid,function (u)
            if arrow:isLoaded() then
                return true
            end
            TrailArrow.WTrail[u]:remove()
        end)


        -- log(Utils.tick.tick(),pos,motion)
        Trail.append(uuid,pos,part,nil,
            {color="#888888",opacity=0.5},motion,
            {color="#0000FF",opacity=0.5},
            {color="#00FF00",opacity=0.5}
        )
    end
    
    -- log(arrow)
    -- return TrailArrow.WTrail
end

local function arrow_render2(delta, arrow)
    local uuid = arrow:getUUID()
    local pos = arrow:getPos(delta)
    local nbt = arrow:getNbt()
    local motion =nbt.Motion and vec(table.unpack(nbt.Motion))
    spd:setText(("%.2f"):format(motion:length()))
    local first = Utils.tick.first_frame_for(uuid)
    if true then


        local part = Utils.parts.child(TrailArrow.WTrail,uuid)
        Utils.tick.register_gc(uuid,function (u)
            if arrow:isLoaded() then
                return true
            end
            TrailArrow.WTrail[u]:remove()
        end)


        -- log(Utils.tick.tick(),pos,motion)
        Trail.append(uuid,pos,part,nil,
            {color="#AAAAFF",opacity=0.25}
        )
    end
    
    -- log(arrow)
    -- return TrailArrow.WTrail
end
function events.arrow_render(delta,arrow)
    pcall(arrow_render2,delta,arrow)
    
end