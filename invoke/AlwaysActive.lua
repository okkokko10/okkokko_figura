require"invoke.Invoke"


local Writing = require"./Writing"

local Text = Writing.makeVirtual()

Text:newLine'global'

Text:newLine'invokeX okkokko I(var!AlwaysActive) run!AlwaysActive'

local initializer_player = {
}
function initializer_player:getUUID()
    return "alwaysActive"
end
function initializer_player:isLoaded()
    return true
end

Invoke.alwaysActive = Invoke.newInstance(Text,initializer_player)


function Invoke.DoAlwaysActive()
    Invoke.alwaysActive:contents()
end