

local freecamKey = keybinds:newKeybind("move freecam's parent", "key.keyboard.e", false)

function freecamKey.press()
    
end

function freecamKey.release()
    
    AnchorAffix.complex.affixInPlace(AnchorAffix.info.getParentID("Freecam"))
    Utils.ID.from("Freecam")
end


local freecam = Utils.ID.field.TestObject:newPart("freecam")

local freecamOn = false

function pings.setFC(state)
    freecamOn = state
end

Freecam = {}

function Freecam.ParentID()
    return AnchorAffix.info.getParentID("Freecam")
end

function Freecam.Parent()
---@diagnostic disable-next-line: undefined-field
    return Utils.ID.from(("Freecam")):getParent()
end


function Freecam.enable()
    pings.setFC(true)
  
end

function Freecam.disable()
  
    renderer:setCameraPivot():setCameraMatrix()
    pings.setFC(false)
end

local head = models:newPart("head","HEAD")


freecam:setPostRender(
      function (delta,ctx,part)
        if freecamOn then
          local pos = part:partToWorldMatrix():apply( vec(0,0,0))
          renderer:setCameraPivot(Utils.Sublevel.nilInAerospace(pos))



          -- local headMat = head:partToWorldMatrix()--:scale(1/PS,1/PS,1/PS)



          -- local ptwm = part:partToWorldMatrix()
          -- local eyep = Utils.entity.entityEyePos(player,delta)
          -- local eyer = player:getRot(delta)
          -- local playerRot = matrices.mat4():rotateY(eyer.y):rotateX(eyer.x)
          -- -- playerRot = matrices.mat4():rotate(eyer.xy_)
          -- -- playerRot = headMat:deaugmented():augmented()
          -- local dif = eyep - pos
          -- local playerMatrix = playerRot * matrices.mat4():translate((dif) * vec(1,-1,1))
          -- -- :scale(1/PS,1/PS,1/PS)
          -- local combined = playerRot * playerMatrix:inverted() --* matrices.translate4(pos)
          -- if Utils.Sublevel.nilInAerospace(combined:apply( vec(0,0,0))) then
          --   renderer:setCameraMatrix(matrices.translate4(headMat:inverted():applyDir(dif)))
          --   -- renderer:setEyeOffset(-dif)
          -- end

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
