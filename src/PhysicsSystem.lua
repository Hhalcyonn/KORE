local log = require(BASE .. "src.log")
local PhysicsSystem = {
    worldgravity = 500,
    worlddrag = 300,
    worldfriction = 400,
}

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
        if not data then goto continue end

        if data.bodytype == "Dynamic" then
            if data.anchored then
                data.velocity.x = 0
                data.velocity.y = 0
                data.force.x = 0
                data.force.y = 0
            else
                local mass = (data.mass and data.mass > 0) and data.mass or 1

                local ax = data.force.x / mass
                local ay = data.force.y / mass

                if PhysicsSystem.worldgravity ~= 0 then
                    ay = ay + (PhysicsSystem.worldgravity * (data.gravityScale or 1))
                end

                local nextVelX = data.velocity.x + ax * dt
                local nextVelY = data.velocity.y + ay * dt

                if data.overSpeedMode == "damp" and data.maxSpeed then
                    if data.maxSpeed.x > 0 and math.abs(nextVelX) > data.maxSpeed.x then
                        if math.abs(nextVelX) > math.abs(data.velocity.x) then
                            nextVelX = data.velocity.x
                        end
                    end
                    if data.maxSpeed.y > 0 and math.abs(nextVelY) > data.maxSpeed.y then
                        if math.abs(nextVelY) > math.abs(data.velocity.y) then
                            nextVelY = data.velocity.y
                        end
                    end
                end

                local dragDamping = math.max(0, 1 - (PhysicsSystem.worlddrag * (data.dragScale or 1) * dt))
                nextVelX = nextVelX * dragDamping
                nextVelY = nextVelY * dragDamping

                if data.overSpeedMode == "clamp" and data.maxSpeed then
                    if data.maxSpeed.x > 0 then
                        nextVelX = clamp(nextVelX, -data.maxSpeed.x, data.maxSpeed.x)
                    end
                    if data.maxSpeed.y > 0 then
                        nextVelY = clamp(nextVelY, -data.maxSpeed.y, data.maxSpeed.y)
                    end
                end

                data.velocity.x = nextVelX
                data.velocity.y = nextVelY

                data.force.x = 0
                data.force.y = 0
            end

        elseif data.bodytype == "Kinematic" then
            if data.anchored then
                data.velocity.x = 0
                data.velocity.y = 0
            end
        end

        ::continue::
    end
end

return PhysicsSystem