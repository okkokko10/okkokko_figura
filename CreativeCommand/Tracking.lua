
local Ccom = require"CreativeCommand.CreativeCommands"


-- display player velocity:
-- !##!
function Ccom.pvec(vector)

    return ('%8.02f : %+8.02f %+8.02f %+8.02f'):format(vector:length(),vector.x,vector.y,vector.z)

    
end
function Ccom.epvec(entity)
    return entity:isLoaded() and Ccom.pvec(entity:getVelocity()*20)
end


---@class WorldAPI
---@field getEntities fun(x1:number,y1:number,z1:number,x2:number,y2:number,z2:number):Entity[]

Ccom.tracking = {}

---comment
---@param center Vector3?
---@param radius number?
---@return Entity[]
function Utils.entity.getEntities(center,radius)
    if not center then
        center = client:getViewer():isLoaded() and client:getViewer():getPos() or vec(0,0,0)
    end
    radius = radius or 1000
    return world.getEntities(center.x - radius,center.y - radius,center.z - radius,center.x + radius,center.y + radius,center.z + radius)
end

---
---@param namePattern string?
---@return string
---@return {[string] : Vector3}
---@return {[string] : Entity}
function Ccom.tracking.trackerVelocities(namePattern)
    namePattern = namePattern or "tracker%s?(.*)"
    
    local radius = 2000
    local entities = Utils.entity.getEntities(nil,radius)
    if not entities then
        return "", {}, {}
    end
    local pretty = {}
    local values = {}
    local entities2 = {}
    for i = 1, #entities do
        local entity = entities[i]
        local name = Ccom.tracking.packageAddress(entity) or entity:getName()
        local matched = string.match(name,namePattern)
        if matched then
            local vel = entity:getVelocity()
            local vel_str = Ccom.pvec(vel*20)
            local pos_str = Ccom.pvec(entity:getPos())
            local str = vel_str .. " | " .. matched .. "\n    | " .. pos_str
            table.insert(pretty,str)
            values[matched] = vel
            entities2[matched] = entity
        end
    end
    return table.concat(pretty,"\n"), values, entities2

    
end

Ccom.tracking.plots = {}
Ccom.tracking.plot_root = models:newPart("PlotRoot", "Skull") --:remove()
Ccom.tracking.plot_root:setPos(0,16,0)
-- Utils.ID.init("Skull",
-- ---comment
-- ---@param s ModelPart
-- function (s)
--     Ccom.tracking.plot_root:moveTo(s)
-- end)
Ccom.tracking.plots_count = 0

function Ccom.tracking.newPlot(key)
    
    local prefab = models:newPart("PlotPrefab"):remove()
    prefab:newText("text"):setText(toJson{color="#FF00FF", text = "."})
    local plt = Ccom.tracking.plot_root:newPart(key)
    plt:setPos(0,0,Ccom.tracking.plots_count * 16)
    plt:newText("name"):setText(key)
    Ccom.tracking.plots[key] = Plot.new(plt,key,prefab)
    Ccom.tracking.plots[key].scale = 1
    Ccom.tracking.plots_count = Ccom.tracking.plots_count + 1
end

function Ccom.tracking.plotEntities(entities)
    
    for key, entity in pairs(entities) do
        local vel = entity:getVelocity()
        local pos = entity:getPos()
        local p = pos.z % 20
        local v = vel.z * 20
        local key2 = key .. "pos"
        if not Ccom.tracking.plots[key] then
            Ccom.tracking.newPlot(key)
            Ccom.tracking.newPlot(key2)
        end
        Ccom.tracking.plots[key]:write(v)
        Ccom.tracking.plots[key2]:write(p)
    end
    return entities
end

function Ccom.tracking.plotTrackerVelocities(namePattern)
    
    local pretty, values, entities = Ccom.tracking.trackerVelocities(namePattern)
    
    if not Utils.tick.first_frame_for("plotTrackerVelocities_" .. (namePattern or "")) then
        return pretty
    end
    Ccom.tracking.plotEntities(entities)


    return pretty
end



---@alias NBT.package.Box 
---| {id : string, count : number, components : {["create:package_contents"] : {[number] : {item : {id : string, count : number}, slot : number}}, ["create:package_order_data"] : {order_id : number, is_final_link : number, fragment_index : number, is_final : number, link_index : number, order_context : {ordered_crafts : {}, ordered_stacks : {entries : {[number] : {item_stack : {id : string, count : number}, count : number}}}}}, ["create:package_address"] : string}}
---| {id : string, count : number, components : { ["create:package_contents"] : {[number] : {item : {id : string, count : number}, slot : number}}}}

---comment
---@param entity Entity
function Ccom.tracking.packageAddress(entity)
    if entity:getType() ~= "create:package" then
        return
    end
    ---@type {Box : NBT.package.Box}
    local nbt = entity:getNbt()
    local address = ((nbt.Box or {}).components or {})["create:package_address"]
    return address
end

-- !#Ccom.epvec(player)#! | Player !#"\10"#!!#Ccom.epvec(world.getEntity("e17a6299-5fb5-400a-be6c-837769f7e7e9"))#! | Sail 1!#"\10"#!!#Ccom.epvec(world.getEntity("c079dd3f-70f7-4e6d-afa1-dd9ae28890d5"))#! | Hull
-- !#Ccom.epvec(world.getEntity("e17a6299-5fb5-400a-be6c-837769f7e7e9"))#! | Sail 1!#"\10"#!!#Ccom.epvec(world.getEntity("c079dd3f-70f7-4e6d-afa1-dd9ae28890d5"))#! | Hull

-- !#Ccom.tracking.plotTrackerVelocities()#!



--- idea: the torsion spring sets the next one to return fast as it passes the middle

--[[


!#Ccom.epvec(world.getEntity("c079dd3f-70f7-4e6d-afa1-dd9ae28890d5"))#! | Hull !#"\10"#!!#Ccom.epvec(world.getEntity("e17a6299-5fb5-400a-be6c-837769f7e7e9"))#! | Sail 1!#"\10"#!Sail 1 Angle: !#math.floor(world.getBlockState(20481034,129,20509704 ):getEntityData().TorsionSpringOutput.Angle)#!
]]