local PhysicsSystem = {}
local deltatime

local function clamp(value, min, max)
    if value > max then
        value = max
    elseif value < min then
        value = min
    end
    return value
end

function PhysicsSystem.update(entities, dt)
    for _, obj in pairs(entities) do
        if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
            obj.velocityy = obj.velocityy + obj.gravity * dt
        end
        if obj.dragval and obj.dragval ~= 0 and obj.velocityx then
            local dragForce = obj.dragval * dt
            if obj.velocityx > 0 then
                obj.velocityx = math.max(0, obj.velocityx - dragForce)
            elseif obj.velocityx < 0 then
                obj.velocityx = math.min(0, obj.velocityx + dragForce)
            end
        end
        if obj.maxspeed and obj.maxspeed ~= 0 then
            obj.velocityx = clamp(obj.velocityx, -obj.maxspeed, obj.maxspeed)
        end
    end
end

return PhysicsSystem