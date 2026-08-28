

local freecamKey = keybinds:newKeybind("move freecam's parent", "key.keyboard.e", false)

function freecamKey.press()
    
end

function freecamKey.release()
    
    AnchorAffix.complex.affixInPlace(AnchorAffix.info.getParentID("Freecam"))
    Utils.ID.from("Freecam")
end


local freecam = Utils.ID.field.TestObject:newPart("freecam")



freecam:setPostRender(
      function (delta,ctx,part)
        if GIZMO.cameraTracking then
          local pos = part:partToWorldMatrix():apply( vec(0,0,0))
          renderer:setCameraPivot(Utils.Sublevel.nilInAerospace(pos))
        end
        if freecamKey:isPressed() then
            local pare = AnchorAffix.info.getParentID("Freecam")
            local change = player:getLookDir() * (16 / (client.getFPS()+1))
            AnchorAffix.complex.affixInPlace(pare,nil,Conversion.toMatrix(pare):translate(change),true)
        end
      end
    )

Utils.ID.field.Freecam = freecam
Grabbing.addSelectableGenerate("Freecam")
    