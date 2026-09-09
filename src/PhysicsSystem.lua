local PhysicsSystem = {
    worldgravity = 500,
    worlddrag = 300,
    worldfriction = 400,
}
local gravity_y = data

local function clamp(value, min, max)
    if value > max then
        value = max
    elseif value < min then
        value = min
    end
    return value
end

function PhysicsSystem:setWorldGravity(value)
    self.worldgravity = value
end

function PhysicsSystem:setWorldDrag(value)
    self.worlddrag = value
end

function PhysicsSystem:setWorldFriction(value)
    self.worldfriction = value
end

function PhysicsSystem.update(entitylist, dt)
    for _, entity in pairs(entitylist) do
        local data = entity.physics
        if data ~= nil and entity.physics.bodytype  == "Dynamic" then
            if not data.anchored then
                if PhysicsSystem.worldgravity ~= 0 then
                    data.force.y = data.force.y + data.mass * (PhysicsSystem.worldgravity * data.gravityScale) * dt
                end
                if data.grounded and data.frictionScale ~= 0 then
                    data.velocity.x = data.velocity.x + (1 - (PhysicsSystem.worldfriction * data.frictionScale) + (PhysicsSystem.worlddrag * data.dragScale) * dt)
                    data.velocity.y = data.velocity.y + (1 - (PhysicsSystem.worldfriction * data.frictionScale) + (PhysicsSystem.worlddrag * data.dragScale) * dt)
                else
                    data.velocity.x = data.velocity.x + (1 - (PhysicsSystem.worlddrag * data.dragScale) * dt)
                    data.velocity.y = data.velocity.y + (1 - (PhysicsSystem.worlddrag * data.dragScale) * dt)
                end
                data.velocity.x = data.velocity.x + (data.force.x / data.mass) * dt
                data.velocity.y = data.velocity.y + (data.force.y / data.mass) * dt
                if data.maxSpeed.x ~= 0 then
                    clamp(data.velocity.x, -data.maxSpeed.x, data.maxSpeed.x)
                end
                if data.maxSpeed.y ~= 0 then
                    clamp(data.velocity.y, -data.maxSpeed.y, data.maxSpeed.y)
                end
                data.force.x = 0
                data.force.y = 0
            end
        elseif data ~= nil and entity.physics.bodytype == "Kinematic" then
            if not data.anchored then
                
            end
        end
    end
end

return PhysicsSystem