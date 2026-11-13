

local Ccom = require"CreativeCommand.CreativeCommands"


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