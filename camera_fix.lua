--- not mine

-- stupidass create wonky cam fix
if host:isHost() then
  events.WORLD_RENDER:register(function(delta)
    -- checks for freecam
    -- checks if we're specifically sitting on a create seat
    if not ((client.getCameraEntity() ~= player) or (world.getPlayers().FreeCamera ~= nil)) and player:getVehicle() and player:getVehicle():getType() == "create:seat" then
      renderer:setCameraRot(((player:getRot(delta).xy_ + vec(0, renderer:isCameraBackwards() and 180 or 0, 0))) * vec(renderer:isCameraBackwards() and -1 or 1, 1, 1))
    else
      renderer:setCameraRot() -- remove any override if we're not seated or in freecam
    end
  end)
end