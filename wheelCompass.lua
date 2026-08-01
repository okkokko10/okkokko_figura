
require "utils"

require "kineticsPath"

-- do return end

-- local compassDirection = vec(0,0,1)
WheelCompass = {
  compassWheel = nil,
  -- lastWheel = nil
  compassTarget = nil

}


-- todo: looking at a steering wheel gives an indicator of the direction it's pointing.
local COMPASS

GIZMO = {
  offset = -45,
  eye_height = 0.7,
  height = 0.1,
  speed = 1,
  display = false,
  noDirectNBT = false
}




function events.entity_init()

  local playerFollow = models:newPart("playerFollow","World")
    :setPreRender(
      function(delta, ctx, part)
        if not player:isLoaded() then return end
        part:setPos(PS*(player:getPos(delta)))
      end
    )

  models.playerFollow:newPart("floatingGizmo")
    :setPreRender(
      function(delta, ctx, part)
        if not player:isLoaded() then return end
        local playerRot = player:getRot(delta)
        local eyeHeight = player:getEyeHeight()
        local dir = vectors.angleToDir(0,playerRot.y+GIZMO.offset)

        part:setPos(PS*(dir + vec(0,1,0) * (eyeHeight*GIZMO.eye_height + GIZMO.height)))
      end
    )

    
  COMPASS = models.playerFollow.floatingGizmo:newPart("compass"):setPos():setVisible(true) --:setVisible(false)

  COMPASS:setScale(0.25)

  COMPASS:newPart("wheel")
    :setPreRender(
      function(delta, ctx, part)
        if WheelCompass.compassWheel then
          part:setRot(0,WheelCompass.compassWheel.x or 0,0)
        end
        part:getTask("straight"):setVisible(WheelCompass.compassWheel)
      end
    )
    :newItem("straight")
      :setItem("red_stained_glass")
      :setLight(15,15)
      :setScale(.13,.12,1) --:setVisible(true)
      :setPos(PS*vec(0,0,-1))

    
  COMPASS:newPart("wheelTarget")
    :setPreRender(
      function(delta, ctx, part)
        
        if WheelCompass.compassWheel then
          part:setRot(0,WheelCompass.compassWheel.y or 0,0)
        end
        part:getTask("straight"):setVisible(WheelCompass.compassWheel)
      end
    )
    :newItem("straight")
      :setItem("orange_stained_glass")
      :setLight(15,15)
      :setScale(.12,.13,1) --:setVisible(true)
      :setPos(PS*vec(0,0,-0.98))

  COMPASS:newPart("base")
    :newItem("center")
      :setItem("blue_stained_glass")
      :setLight(15,15)
      :setScale(.2,.2,.2) --:setVisible(true)
  COMPASS.base
    :newItem("plate")
      :setItem("blue_stained_glass")
      :setLight(15,15)
      :setPos(PS*vec(0,-0.2,0))
      :setScale(1,.2,1) --:setVisible(true)
  COMPASS.base
    :newItem("north")
      :setItem("red_stained_glass")
      :setLight(15,15)
      :setPos(PS*vec(0,-0.2,-0.35))
      :setScale(.1,.1,.1) --:setVisible(true)
      
  
  
  COMPASS:newPart("player")
    :setPreRender(
      function(delta, ctx, part)
        if not player:isLoaded() then return end
        local playerRot = player:getRot(delta)
        part:setRot(0,180-playerRot.y,0)
      end
    )
    :newItem("straight")
      :setItem("gray_stained_glass")
      :setLight(15,15)
      :setScale(.1,.1,1) --:setVisible(true)
      :setPos(PS*vec(0,0,-0.95))
  
  COMPASS:newPart("target")
    :setPreRender(
      function(delta, ctx, part)
        if WheelCompass.compassTarget then
          part:setRot(0,WheelCompass.compassTarget, 0)
        end
        part:getTask("straight"):setVisible(WheelCompass.compassTarget)
      end
    )
    :newItem("straight")
      :setItem("white_stained_glass")
      :setLight(15,15)
      :setScale(.11,.09,1) --:setVisible(true)
      :setPos(PS*vec(0,0,-0.94))

  COMPASS:newPart("velocity")
    :setPreRender(
      function(delta, ctx, part)
        if not player:isLoaded() then return end
        local vel = player:getVelocity()
        part:setPos(PS*GIZMO.speed*vel)
      end
    )
    :newItem("node")
      :setItem("light_blue_concrete")
      :setLight(15,15)
      :setScale(.15,.15,.15) --:setVisible(true)
  COMPASS:newPart("velocityTextBase"):setPos(PS*vec(0,0.3,0))
    :newPart("billboard","BILLBOARD")
      :setPreRender(
        function(delta, ctx, part)
          if not player:isLoaded() then return end
          local vel = player:getVelocity()
          local speed = vel:length()*20
          part:getTask("text"):setText(speed < 0.1 and "" or (math.floor(speed*10)/10))
        end
      )
    :newText("text")
      :setText("unset")
      :setLight(15,15)
      -- :setPos(PS*vec(0,-0.2,-0.35))
      :setScale(.2) --:setVisible(true)
      :setSeeThrough(true)
      :setAlignment("CENTER")

  COMPASS:newPart("nbtTextBase"):setPos(PS*vec(0,-0.3,0))
    :newPart("billboard","BILLBOARD")
      :setPreRender(
        function(delta, ctx, part)
          part:getTask("text"):setText(KineticsPath.firstNBT or "")
        end
      )
    :newText("text")
      :setText("unset")
      :setLight(15,15)
      -- :setPos(PS*vec(0,-0.2,-0.35))
      :setScale(.2) --:setVisible(true)
      :setSeeThrough(true)
end




local mainPage = action_wheel:getPage("mainPage")


function pings.setTargetHeading(value)
  WheelCompass.compassTarget = value
  -- log(value)
end


function pings.setGizmo(attr,value)
  GIZMO[attr]=value
end

mainPage:newAction()
    :title("Set Target Heading")
    :item("minecraft:compass")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function()
      
      if not player:isLoaded() then return end
      local playerRot = player:getRot(delta)
      pings.setTargetHeading(180-playerRot.y)
    end)
    :onRightClick(function()      
      pings.setTargetHeading(nil)
    end)
    :onScroll(
      function (dir)
        pings.setGizmo("height",GIZMO.height + dir * 0.1)
      end

    )





mainPage:newAction()
    :title("Toggle Gizmo")
    :item("minecraft:end_rod")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function()
      pings.setGizmo("display",not GIZMO.display)
    end)
    :onRightClick(function()
      pings.setGizmo("noDirectNBT",not GIZMO.noDirectNBT)
    end)
    :onScroll(
      function (dir)
        pings.setGizmo("offset",GIZMO.offset + dir * 5)
      end

    )




function pings.setCompassRotation(value)
  WheelCompass.compassWheel = value
  -- log(value)
end


function WheelCompass.getSteeringWheelAngles(block)
  
  if not (block and block:getID() == "simulated:steering_wheel") then return end
  -- local wheel = world.getBlockState(WheelCompass.lastWheel)
  local data = block:getEntityData()
  if not data then return end
  local rotat = vec(data.Angle or 0,data.TargetAngle or 0)

  -- steering wheels flip their orientation when facing west or north
  local props = block:getProperties() or {}
  if props.facing == "west" or props.facing == "north" then
    rotat = -rotat
  end
  return rotat

end


function events.tick()
  if not player:isLoaded() then return end
  
  COMPASS:setVisible(not not (WheelCompass.compassWheel or WheelCompass.compassTarget or GIZMO.display))
  if host:isHost() then
    -- local block, hitPos, side = host:getPickBlock()
    


    local block, pos = KineticsPath.getFirstBlock()

    local rotat = WheelCompass.getSteeringWheelAngles(block)
    
    if WheelCompass.compassWheel ~= rotat then
        pings.setCompassRotation(rotat)
    end
    
  end

end