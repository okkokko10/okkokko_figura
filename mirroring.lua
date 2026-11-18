

local TARGET_ORIGINAL = true
local TARGET_REQUIRE_HOLDING = false
local PREVIEW_BLOCK_TARGET = false
local EXTRA_HEIGHT = 0
local ENABLE_AVATARS = true
local VISIBLE_OTHERS = true
local AVATAR_HOLD_ITEM = true


--- todo: make the entity and block not flip. (flip offhand for entity)

Mirroring = {}


---xzf
---@type Matrix4[]
Mirroring.reflect_matrices = {}
for i = 0, 7 do

    local sx = bit32.btest(i,1) and -1 or 1
    local sz = bit32.btest(i,2) and -1 or 1
    local flip = bit32.btest(i,4)
    local ex = vec(sx,0,0,0)
    local ez = vec(0,0,sz,0)
    if flip then
        ex,ez = ez,ex
    end

    Mirroring.reflect_matrices[i] = matrices.mat4(
            ex,
            vec(0,1,0,0),
            ez,
            vec(0,0,0,1)
        )



end



---@type Vector3?
Mirroring.pos = nil


Mirroring.root = models:newPart("MirroringRoot"):remove()
Mirroring.rootRoot = Mirroring.root:newPart("root")
Mirroring.rootRight = Mirroring.root.root:newPart("right")
Mirroring.rootFlipped = Mirroring.root.root:newPart("flipped")


Mirroring.player_difference = matrices.mat4()



Mirroring.reflection = Mirroring.root:newPart("reflection"):remove()
Mirroring.original = Mirroring.rootRight:newPart("original")

---@type EntityTask
Mirroring.plr = nil

Mirroring.old_hand = nil
function Mirroring.update_hand(item_id)
    if item_id == Mirroring.old_hand then
        return
    end
    Mirroring.old_hand = item_id
    if AVATAR_HOLD_ITEM then
        Mirroring.plr:setNbt("minecraft:vex",toJson{
        HandItems = {{id = item_id or nil},{id = "create:wand_of_symmetry"}}
    })
    end
    if PREVIEW_BLOCK_TARGET then
        Mirroring.target:item(item_id or "minecraft:white_stained_glass")
    end
    
end

function Mirroring._init_plr()
    
    local plr = Mirroring.reflection:newPart("player"):newPart("flip"):newPart("entity"):newEntity("player")
    Mirroring.plr = plr
    Mirroring.entity = Mirroring.reflection.player.flip.entity

    
    Mirroring.plr:setNbt("minecraft:vex",toJson{
        HandItems = {{},{id = "create:wand_of_symmetry"}}
    })

    plr:setRot(0,180,0)
    :setOverlay(10,15)
    :setLight(13)

    local ent = plr:asEntity()
    if ent then
        Mirroring.plr_eyes = ent:getEyeHeight()
        plr:setPos(0,-PS*Mirroring.plr_eyes,0)
    end
    

    Mirroring.target = Mirroring.reflection:newPart("target"):newPart("flip"):newItem("target")
    Mirroring.target:item("minecraft:white_stained_glass")
    :setScale(0.9)
    if TARGET_ORIGINAL then
        Mirroring.rootRight:addChild(Mirroring.reflection.target)
    end

    
    
end
Mirroring._init_plr()

function Mirroring.flips(mat)
    Mirroring.reflection.target.flip:setMatrix(mat)
    -- Mirroring.reflection.player.flip:setMatrix(mat)
    
end

-- function Mirroring.rootRight.preRender()
--     Mirroring.reflection.target.flip:setMatrix(matrices.mat4())
--     -- Mirroring.reflection.player.flip:setMatrix(matrices.mat4())

-- end
-- function Mirroring.rootFlipped.preRender()
--     Mirroring.reflection.target.flip:setMatrix(Mirroring.reflect_matrices[1])
--     -- Mirroring.reflection.player.flip:setMatrix(Mirroring.reflect_matrices[1])
-- end



---@type ModelPart[]
Mirroring.mirrors = {}

for i = 1, 7 do
    local m = Mirroring.rootRoot[(bit32.btest(i,1) == bit32.btest(i,2)) and "right" or "flipped"]:newPart(tostring(i))
    Mirroring.mirrors[i] = m
    m:addChild(Mirroring.reflection)
    
    m:setMatrix(
        Mirroring.reflect_matrices[i]
    )
    function m.preRender()
        Mirroring.flips(Mirroring.reflect_matrices[i])
    end

end


---@type LerpMatrix
Mirroring.slOriginMatrixLerp = {current = matrices.mat4()}

function Mirroring.setMirror(bitmask,x,y,z)
    local pos = x and vec(x,y or 0,z or 0)
    
    if pos and pos ~= Mirroring.pos then
        Mirroring.pos = pos
        Mirroring.slOriginMatrixLerp = select(2,Utils.Sublevel.SublevelPositionPart(pos,nil,Mirroring.root,vec(1,1,1)/2))
        
    end

    Mirroring.setActive(bitmask or 0)

end

---@param bitmask integer
function Mirroring.setActive(bitmask)
    if Mirroring.bitmask ~= bitmask then
        Mirroring.bitmask = bitmask
        for i = 1, 7 do
            Mirroring.mirrors[i]:setVisible(bit32.extract(bitmask,i) == 1)
            
        end
        
    end

end

function Mirroring.setNone()
    return Mirroring.setMirror(0)
end


Mirroring.planes = {
        plane = {
            [0] = 4,
            [1] = 2,
        },
        cross_plane = {
            [0] = 2 + 4 + 8,
            [1] = 8 + 16 + 128
        },
        triple_plane = {
            [0] = 254
        }
    }

---comment
---@param tag table?
function Mirroring.fromSymmetry(tag)

    if not (tag and tag["create:symmetry_wand_enable"] == 1) then
        return
    end

    local d = tag["create:symmetry_wand"]
    ---@type "empty"|"plane"|"cross_plane"|"triple_plane"
    local tp = d["type"]
    --- Along Z/X, Orthogonal/Diagonal
    ---@type 0|1
    local orientation_index = d["orientation_index"]
    local p = d["position"]
    ---@type Vector3
    local position = p and vec(table.unpack(p))
    local x,y,z = table.unpack(p)


    local bitmask = (Mirroring.planes[tp] or {})[orientation_index]
    return bitmask,x,y,z
    
    -- Mirroring.setMirror(position,bitmask or 0)

    
    -- return true

    



    
end


--- idea: make generic, such that all things that check the hotbar use the same one
function Mirroring.fromHotbar()
    local inventory = player:getNbt().Inventory
    if not inventory then return end
    for i = 1, 9 do
        local item = inventory[i]
        if item and item.Slot and item.Slot >=0 and item.Slot < 9 then -- item is in hotbar
            if item.id == "create:wand_of_symmetry" then
                Mirroring.wand = item
                local bitmask, x, y, z = Mirroring.fromSymmetry(item.components)
                if bitmask then
                    return bitmask, x, y, z
                end
            end

        end
    end
    return nil, nil, nil, nil
    
end

pings.setMirror = Mirroring.setMirror

function Mirroring.setPing(bitmask,x,y,z)
    -- log(bitmask,x,y,z)
    if VISIBLE_OTHERS then
        pings.setMirror(bitmask,x,y,z)
        
    else
        Mirroring.setMirror(bitmask,x,y,z)
        
    end
    
end


Mirroring.old_values = {}
function Mirroring.update()
    if not player:isLoaded() then return end
    local bitmask, x, y, z = Mirroring.fromHotbar()
    if 
        Mirroring.old_values.bitmask == bitmask and 
        Mirroring.old_values.x == x and 
        Mirroring.old_values.y == y and 
        Mirroring.old_values.z == z then 
    else
        Mirroring.old_values.bitmask = bitmask
        Mirroring.old_values.x = x
        Mirroring.old_values.y = y
        Mirroring.old_values.z = z
        Mirroring.setPing(bitmask,x,y,z)
    end


end


-- Mirroring.reflection:newPart("shine")

 



Mirroring.root:setMidRender(function (delta, context, part)
    if not player:isLoaded() then return end

    if not (Mirroring.slOriginMatrixLerp.loaded and Mirroring.pos) then
        Mirroring.root.root:setVisible(false)
        -- todo: should make it invisible
        return
    end
    Mirroring.root.root:setVisible(true)

    local item_id = player:getHeldItem().id
    local holding_wand = item_id == "create:wand_of_symmetry"
    
    if item_id == "minecraft:air" then
        item_id = nil
    end
    Mirroring.update_hand(item_id)

    local player_matrix = matrices.scale4(1/16):translate(player:getPos(delta) + vec(0,player:getEyeHeight() + EXTRA_HEIGHT,0))

    if ENABLE_AVATARS then
        Mirroring.reflection.player:setVisible(true)
        local root_matrix = part:partToWorldMatrix()
        Mirroring.player_difference = root_matrix:inverted() * player_matrix

        Mirroring.reflection.player:setMatrix(Mirroring.player_difference)



        local yaw = player:getBodyYaw(delta)
        local rot = player:getRot(delta)
        Mirroring.plr:setHeadRotation(rot - vec(0,yaw))
        Mirroring.plr:setRot(0,-yaw)

        local position = Mirroring.player_difference:apply()
        local range = position:length() / (50*16)
        Mirroring.entity:scale(math.clamp(2-range*2,0.00,1))
    else
        
        Mirroring.reflection.player:setVisible(false)
    end



    local target, hit_pos, side = player:getTargetedBlock(true)
    if target and target:getID() ~= "minecraft:air" and (holding_wand or not (TARGET_REQUIRE_HOLDING)) and (Mirroring.bitmask ~= 0) then
        Mirroring.target:setVisible(true)
        local side_dir = Direction.toVector(side)

        local target_offset = (target:getPos() - Mirroring.pos) + side_dir
        Mirroring.reflection.target:setPos(target_offset*PS)
        local t_range = target_offset:length() / 50
        local t_range2 = math.clamp(2.5-t_range*2,0,1)
        if t_range >= 1 then
            t_range2 = 0
        end

        Mirroring.reflection.target:setScale(t_range2)
    else
        Mirroring.target:setVisible(false)
        -- Mirroring.root.target:setVisible(false)
    end
    
    

    

    

end)


if host:isHost() then
    events.TICK:register(Mirroring.update)
end



return Mirroring