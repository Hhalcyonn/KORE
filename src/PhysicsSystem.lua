local BASE = "KORE."
local log = require(BASE .. "src.log")
local config = require(BASE .. "config").PhysicsSystem
local PhysicsSystem = {
    worldgravity = config.worldgravity,
    worlddrag = config.worlddrag,
    worldfriction = config.worlddrag,
    enabled = true
}
local logged = false
local lastenabled = PhysicsSystem.enabled

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
    log.debug("World gravity set to " .. tostring(value))
end

function PhysicsSystem:setWorldDrag(value)
    self.worlddrag = value
    log.debug("World drag set to " .. tostring(value))
end

function PhysicsSystem:setWorldFriction(value)
    self.worldfriction = value
    log.debug("World friction set to " .. tostring(value))
end

function PhysicsSystem:enablePhysics(bool)
    self.enabled = bool
end

local function checkenabled()
        if lastenabled ~= PhysicsSystem.enabled then
            logged = false
            lastenabled = PhysicsSystem.enabled
        end
    end

function PhysicsSystem.update(entitylist, dt)
    checkenabled()

    if not PhysicsSystem.enabled then
        if not logged then
            log.info("Physics disabled.")
            logged = true
        end
        goto continue
    end

    if config.physics_mode == "advanced" then
        if not logged then
            log.info("using advanced physics mode.")
            logged = true
        end
        for _, entity in pairs(entitylist) do
            local data = entity.physics
            if not data then goto continue2 end

            if data.bodytype == "Dynamic" then
                if not data.velocity or not data.force then
                    log.warn(
                    tostring(entity.identity.name or entity.identity.id) .. " ;Dynamic entity is missing velocity or force data. Force exist velocity and force."
                    )
                    data.velocity = {x = 0, y = 0}
                    data.force = {x = 0, y = 0}
                end
                if data.anchored then
                    data.velocity.x = 0
                    data.velocity.y = 0
                    data.force.x = 0
                    data.force.y = 0
                else
                    local mass = (data.mass and data.mass > 0) and data.mass or 1

                    local ax = data.force.x / mass
                    local ay = data.force.y / mass

                    if PhysicsSystem.worldgravity ~= 0 and not entity.physics.grounded then
                        ay = ay + (PhysicsSystem.worldgravity * (data.gravityScale or 1))
                    end

                    local nextVelX = data.velocity.x + ax * dt
                    local nextVelY = data.velocity.y + ay * dt

                    local dragDamping = math.max(
                        0,
                        1 - ((PhysicsSystem.worlddrag * (data.dragScale or 1) / mass) * dt)
                    )
                    nextVelX = nextVelX * dragDamping
                    nextVelY = nextVelY * dragDamping

                    local EPSILON = 0.1
                    if math.abs(nextVelX) < EPSILON then nextVelX = 0 end
                    if math.abs(nextVelY) < EPSILON then nextVelY = 0 end

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
            ::continue2::
        end
    elseif config.physics_mode == "simple" then
        if not logged then
            log.info("using simple physics mode.")
            logged = true
        end
        for _, entity in pairs(entitylist) do
            local data = entity.physics
            if data ~= nil then
                if not data.anchored then
                    local enteringVelX = data.velocity.x
                    local enteringVelY = data.velocity.y

                    data.velocity.x = data.velocity.x * math.max(0, 1 - (data.drag or 0) * dt)

                    if data.overSpeedMode == "clamp" and data.maxSpeed then
                        if data.velocity.x > data.maxSpeed then
                            data.velocity.x = data.maxSpeed
                        elseif data.velocity.x < -data.maxSpeed then
                            data.velocity.x = -data.maxSpeed
                        end
                    elseif data.overSpeedMode == "damp" and data.maxSpeed then
                        if math.abs(data.velocity.x) > data.maxSpeed
                        and math.abs(data.velocity.x) > math.abs(enteringVelX) then
                            data.velocity.x = enteringVelX
                        end
                    end

                    local terminalVelocity = (data.drag and data.drag > 0) and ((data.gravity or 0) / data.drag) or math.huge
                    data.velocity.y = data.velocity.y + (data.gravity or 0) * dt
                    if data.overSpeedMode == "clamp" then
                        if data.velocity.y > terminalVelocity then
                            data.velocity.y = terminalVelocity
                        end
                    elseif data.overSpeedMode == "damp" then
                        if data.velocity.y > terminalVelocity
                        and math.abs(data.velocity.y) > math.abs(enteringVelY) then
                            data.velocity.y = enteringVelY
                        end
                    end
                else
                    data.velocity = {x = 0, y = 0}
                end
            end
        end
    end
    ::continue::
end

return PhysicsSystem