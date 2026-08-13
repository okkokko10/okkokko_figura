
local AlwaysPresent = {__index = function (self, k)
    self[k] = {}
    return self[k]
end}


GrabAttributes = setmetatable({},AlwaysPresent)



return GrabAttributes