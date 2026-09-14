local BASE = "KORE."
local log = require(BASE .. "src.log")
local PhysicsSystem = {
    worldgravity = 500,
    worlddrag = 300,
    worldfriction = 400,
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

    if type(dt) ~= "number" or dt < 0 then
        if not logged then
            log.error("Physics update received invalid delta time: " .. tostring(dt) .. "Will continue without Physics.")
        end
        logged = true
        goto continue
    end
    if not logged then
        log.info("PhysicsSystem updating succesfully.")
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

                if PhysicsSystem.worldgravity ~= 0 then
                    ay = ay + (PhysicsSystem.worldgravity * (data.gravityScale or 1))
                end

                local nextVelX = data.velocity.x + ax * dt
                local nextVelY = data.velocity.y + ay * dt

                 if data.overSpeedMode and not data.maxSpeed then log.warn(tostring(entity.identity.name or entity.identity.ID) .. " ;Dynamic body entity has overSpeedMode but not maxSpeed. Force exist maxSpeed to 1000.") data.maxSpeed = {x = 1000, y = 2000} end

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
        ::continue2::
    end
    ::continue::
end

return PhysicsSystem