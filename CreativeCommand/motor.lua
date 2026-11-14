

local Ccom = require"CreativeCommand.CreativeCommands"


--#region motorcontrol


Ccom.motor = {}


---sets a creative motor here
---@param pos Vector3
---@param speed any
---@param facing? string
function Ccom.motor.setMotor(pos,speed, facing)
    local p = Ccom.helper.vector(pos)
    local block = world.getBlockState(pos)
    if block.id ~= "create:creative_motor" then return end
    local ed = block:getEntityData()
    if (not ed) or (ed.ScrollValue == speed) then return end -- there is no change
    facing = facing or block.properties.facing or "up"
    Ccom.sendChatCommand(("setblock %s stone"):format(p))
    Ccom.sendChatCommand(("setblock %s create:creative_motor[facing=%s]{ScrollValue:%s}"):format(Ccom.helper.vector(pos),facing,tostring(speed)))
    

end
function Ccom.motor.suppressSetblockResult(pos)
    local match = ('{"translate":"commands.setblock.success","with":[%s]}'):format(Ccom.helper.WEvector(pos))
    local function erasef(message,json)
        if json and string.find(json,match,1,true) then
            return false
        end
    end
    events.CHAT_RECEIVE_MESSAGE:register(erasef,"suppressSetblockResult:" .. Ccom.helper.WEvector(pos))
    
end

function Ccom.motor.suppressSetblockResultFull()
    Pinned.inactive = true
    local function erasef(message,json)
        if message and string.find(message,'Changed the block at',1,true) then
            return false
        end
    end
    events.CHAT_RECEIVE_MESSAGE:register(erasef)
    
end



function Ccom.motor.piston(pos,motor_pos,scale)
    scale = scale or 1
    local speed_ = nil
    -- Ccom.motor.suppressSetblockResult(motor_pos)
    ---@class Motor.Piston
    local out = {
        getOffsetLength = function(self)
            local q = world.getBlockState(pos):getEntityData() or {}
            return q.Offset, q.ExtensionLength
        end,
        setSpeed = function (self,speed)
            speed_ = speed
            Ccom.motor.setMotor(motor_pos,speed*scale)
        end,
        getSpeed = function (self)
            if speed_ then return speed_ end
            local q = world.getBlockState(motor_pos):getEntityData() or {}
            return (q.ScrollValue or 0) / scale
        end,
    }
    return out

end


Ccom.motor.program = {
    ---@type Motor.Piston[]
    pistons = {},
    pos1 = vec(20481033,129,20491272),
    count = 22,
    offsets = {},
    lengths = {},
    weight = {},
    active = {1}
}
local program = Ccom.motor.program

for i = 1, program.count do
    program.pistons[i] = Ccom.motor.piston(program.pos1+vec(0,1-i,0),program.pos1+vec(0,0,1)+vec(0,1-i,0),-256)
end




function Ccom.motor.run()
    local momentum = 0 -- unused currently
    for i = 1, program.count do
        local p = program.pistons[i]
        
        local offset,length = p:getOffsetLength()
        if offset then
            program.offsets[i] = offset
            program.lengths[i] = length
        end
        momentum = momentum + p:getSpeed() * (program.weight[i] or 1)

    end



    for i = 1, program.count do
        local p = program.pistons[i]
        local offset = program.offsets[i] or 0
        local length = program.lengths[i] or 16
        
        if program.active[i] then
            local edge = (offset < 2) and 1 or (length - offset < 2) and -1 or 0

            if edge * program.active[i] == 1 then
                p:setSpeed(1)
            end
            if edge * program.active[i] == -1 then
                p:setSpeed(-1/2)
                program.active[i+1] = -program.active[i]
            end
            
        end
    end
end

function Ccom.motor.start()
    
    Ccom.motor.suppressSetblockResultFull()
    events.TICK:register(Ccom.motor.run,"motor_run")
end

function Ccom.motor.stop()
    events.TICK:remove("motor_run")
end

function Ccom.motor.reset()
    Ccom.motor.stop()
    program.active = {1}
    for i = 1, program.count do
        local p = program.pistons[i]
        p:setSpeed(-1)
    end
    
end


--#endregion