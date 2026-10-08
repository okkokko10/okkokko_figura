require"invoke.Invoke"


local Trail = {}


Trail._lastPos = Utils.table.kmode()


---comment
---@param trail any
---@param vertex Vector
---@param parent ModelPart<"World">
---@param config DrawLineConfig?
---@param derivative Vector?
---@param dconfig DrawLineConfig?
function Trail.append(trail,vertex,parent,min_motion,config,derivative,dconfig)
    vertex = Utils.Sublevel.sableSublevelToWorld(vertex)
    local last_pos = Trail._lastPos[trail]
    if not last_pos then
        Trail._lastPos[trail] = vertex
        return
    end
    if vertex then
        if (vertex-last_pos):length() <= min_motion then
            return
        end
        if derivative and derivative:length() > min_motion then
            -- log(vertex,derivative)
            DrawLine.line(parent,vertex*PS,(vertex+derivative)*PS,dconfig)
        end

        DrawLine.line(parent,last_pos*PS,vertex*PS,config)
    end
    Trail._lastPos[trail] = vertex
end
function Trail.clear(trail,parent)
    Trail._lastPos[trail] = nil
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
        parent = Utils.parts.child(input.parent,"Trail","World")
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

    local config = {color = input.color}

    Trail.append(trailID,position,parent,min_motion,config,input.derivative,{color="#0000FF"})
    -- return parent
    

    -- local current_matrix =  input:partToWorldMatrix()

    -- local trail = input.Trail or input:newPart("Trail","World")
    -- local trail_last = input.TrailLast
    -- if not trail_last then
    --     trail_last = input:newPart("TrailLast","World")
    -- else
    --     local last_matrix = Utils.conversion.initializedPtwm(trail_last)
    --     if last_matrix then
            
    --     local last_pos = last_matrix:apply()
    --     local current_pos =  current_matrix:apply()
    --     if (last_pos-current_pos):length() < min_motion then
    --         return trail -- do not update trail_last position.
    --     end

    --     DrawLine.line(trail,last_pos*PS,current_pos*PS,
    --     {
    --         -- color="#FF8800"
    --     }
    --     )
    --     end
    -- end

    
    -- trail_last:setMatrix(Utils.conversion.ptwmToWorldPartMatrix(current_matrix))
    
    -- return trail
    
end)

--- todo: ask how to get entity nbt for :newEntity():setNbt( )
--- todo: trail of the entity itself