local DirectionalLink = {}

---@source https://github.com/Creators-of-Aeronautics/Simulated-Project/blob/99923cb278add264c29a327d82cb939e03f469cf/simulated/common/src/main/java/dev/simulated_team/simulated/content/blocks/redstone/directional_receiver/DirectionalLinkedReceiverBlockEntity.java#L27
--[[
```
public Tuple<Integer, Double> getSignalFromLink(final Vec3 relativePosition, final int transmittedStrength) {
        final Direction dir = this.getBlockState().getValue(FACING);
        final Vec3 normal = new Vec3(dir.getStepX(), dir.getStepY(), dir.getStepZ());
        final double length = relativePosition.length();

        if (length > AllConfigs.server().logistics.linkRange.get())
            return new Tuple<>(0, 0.0);

        final double dot = relativePosition.dot(normal) / length;

        if (dot < 0) return new Tuple<>(0, 0.0);

        // output to computer craft -> degrees; acos or asin - 90o
        final double angle = Math.asin(dot);
        this.angleToClosestLink = Math.acos(dot);

        final double strengthScalar = Math.clamp((angle / Math.PI) * 2, 0, 1);
        return new Tuple<>((int) Math.ceil(strengthScalar * transmittedStrength), Math.toDegrees(angle));
    }
```
]]

---@param blockState BlockState
---@param relativePosition Vector
---@param transmittedStrength integer
function DirectionalLink.getSignalFromLink(blockState, relativePosition,transmittedStrength)
    
end
