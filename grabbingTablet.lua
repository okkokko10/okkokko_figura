require"tablet"

--- todo: updatable tablet. maybe don't have buttons be parts.

local GrabbingTablet = Tablet.newTablet("GrabbingTablet",{
})

FloatingObject:create(GrabbingTablet.part,
    {
        base = Positioning.parts.PlayerFollowerYaw:newPart("GrabTabletP"):setPos(PS*(0.1),PS*1.5,PS*2),
    }):setID("GrabbingTablet")