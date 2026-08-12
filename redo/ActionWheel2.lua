
require"wheelCompass"

local mainPage = action_wheel:getCurrentPage()


local page = action_wheel:newPage()
action_wheel:setPage(page)


mainPage:newAction()
    :title("change page")
    :item("minecraft:grass_block")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function()
        action_wheel:setPage(page)
    end)


page:newAction()
    :title("change page")
    :item("minecraft:grass_block")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function()
        action_wheel:setPage(mainPage)
    end)

page:newAction()
    :title("look as gizmo")
    :item("minecraft:glass_pane")
    :hoverColor(0.9,0.9,0.9)
    :onLeftClick(function()
      pings.setGizmo("cameraTracking",true)

      if GIZMO.trackingOther then
        -- renderer:setCameraPivot(GIZMO.trackingOther + (vec(0,1,0) * (GIZMO.height)))
        -- GIZMO.cameraTracking = true
      end
      
    end)
    :onRightClick(function()
      renderer:setCameraPivot()
      -- GIZMO.cameraTracking = false
      pings.setGizmo("cameraTracking",false)
    end)

return page