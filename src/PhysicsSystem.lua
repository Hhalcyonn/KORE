local PhysicsSystem = {}
local deltatime
function PhysicsSystem.initializedt(dt)
    deltatime = dt
end

function PhysicsSystem.gravity(obj)
    if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
        obj.velocityy = obj.velocityy + obj.gravity * deltatime
    end
end

function PhysicsSystem.drag(obj)
    if obj.appliedDragval and obj.appliedDragval ~= 0 and obj.velocityx then
        local dragForce = obj.appliedDragval * deltatime
        if obj.velocityx > 0 then
            obj.velocityx = math.max(0, obj.velocityx - dragForce)
        elseif obj.velocityx < 0 then
            obj.velocityx = math.min(0, obj.velocityx + dragForce)
        end
    end
end

function PhysicsSystem.lerp(a, b, t)
    return a + (b - a) * t
end

function PhysicsSystem.clamp(value, min, max)
    if value > max then
        value = max
    elseif value < min then
        value = min
    end
    return value
end

return PhysicsSystem