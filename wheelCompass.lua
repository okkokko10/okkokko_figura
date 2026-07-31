

do return end

-- local compassDirection = vec(0,0,1)
compassRotation = 0

-- todo: looking at a steering wheel gives an indicator of the direction it's pointing.

function events.entity_init()

    
  local compass = models:newPart("compassRoot","World"):newPart("compass"):setVisible(true) --:setVisible(false)

  compass:newItem("straight")
      :setItem("red_stained_glass")
      :setLight(15,15)
      :setScale(.25,.25,1) --:setVisible(true)
      :setPos(vec(0,0,1)*16)
      
end


function events.tick()
  --code goes here
  -- kineticsPath.updateRender()
--   kineticsPath.updateRender()

  models.compassRoot.compass:setPos(16*(player:getPos())):setRot(0,compassRotation,0)
  -- models.compassRoot.compass

end