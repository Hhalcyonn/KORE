local BASE = "KORE."
local bump = require(BASE .. "libs.bump")
local log = require(BASE .. "src.log")
local config = require(BASE .. "config").PhysicsSystem

local WorldSystem = {}

WorldSystem.world = nil

local function collisionfilter(entity, other)
    local entitybodytype
    local otherbodytype
    if entity.physics and
        other.physics and
        entity.physics.bodytype and
        other.physics.bodytype then
        entitybodytype = entity.physics.bodytype
        otherbodytype = other.physics.bodytype
    end
    local entityFilter = entity.collider.collisionfilter or "slide"
    local otherFilter = other.collider.collisionfilter or "slide"
    if entitybodytype and otherbodytype then
        if (entitybodytype == "Kinematic" and otherbodytype == "Kinematic") or
            (entitybodytype == "Kinematic" and otherbodytype == "Static") or
            (entitybodytype == "Static" and otherbodytype == "Kinematic") then
                return "cross"
        elseif entitybodytype == "Static" and otherbodytype == "Static" then
                return nil
        end
    end

    if entityFilter == "touch" or otherFilter == "touch" then
        return "touch"
    elseif entityFilter == "bounce" or otherFilter == "bounce" then
        return "bounce"
    elseif entityFilter == "slide" or otherFilter == "slide" then
        return "slide"
    end

    return entityFilter
end
local function checkdir(item, other)
    local selfdir
    local otherdir
    if item.physics.velocity.x > 0 then
        selfdir = 1
    elseif item.physics.velocity.x < 0 then
        selfdir = -1
    end
    if other.physics.velocity.x > 0 then
        otherdir = 1
    elseif other.physics.velocity.x < 0 then
        otherdir = -1
    end
    return selfdir, otherdir
end
function WorldSystem.initworld(cellsize, worldpack)
    local ECS = require(BASE .. "src.EntityComponentSystem")
    WorldSystem.world = bump.newWorld(cellsize or 64)
    log.info("World initialized with cell size " .. tostring(cellsize or 64))
    if worldpack then
        for _, entitydata in pairs(worldpack) do
            ECS.register(ECS.createentity(entitydata))
        end
        log.info("loaded world from a worldpack.")
    end
end

function WorldSystem.deleteworld()
    WorldSystem.world = nil
    log.info("World deleted")
end

function WorldSystem.addtoworld(entity)
    if WorldSystem.world ~= nil then
        if entity.collider then
            if entity.collider.collision and not WorldSystem.world:hasItem(entity) then
                WorldSystem.world:add(
                    entity,
                    entity.x + entity.collider.offsetx,
                    entity.y + entity.collider.offsety,
                    entity.collider.width,
                    entity.collider.height
                )
            end
        end
    end
end

function WorldSystem.removefromworld(entity)
    if WorldSystem.world ~= nil then
        if WorldSystem.world:hasItem(entity) then
            WorldSystem.world:remove(entity)
        end
    end
end

function WorldSystem.update(entitylist, dt)
    for _, entity in pairs(entitylist) do
        local wasGrounded = false
        if WorldSystem.world ~= nil then

            local vx = entity.physics and entity.physics.velocity and entity.physics.velocity.x
            local vy = entity.physics and entity.physics.velocity and entity.physics.velocity.y

            if vx == nil or vy == nil or entity.physics.anchored then
                goto continue
            end

            local isDynamic, isKinematic, isStatic = false, false, false
            isDynamic = not entity.physics or entity.physics.bodytype == "Dynamic"
            isKinematic = entity.physics and entity.physics.bodytype == "Kinematic"
            isStatic = entity.physics and entity.physics.bodytype == "Static"
            local anchored = entity.physics and entity.physics.anchored

            if isStatic or anchored then
                goto continue
            end

            if entity.collider and entity.collider.collision and WorldSystem.world:hasItem(entity) and not entity.physics.anchored then
                if entity.physics.grounded ~= nil then
                    wasGrounded = entity.physics.grounded
                end

                local extraVx, extraVy = 0, 0
                if isDynamic and wasGrounded then
                    local probe = 2
                    local _, _, gcols, glen = WorldSystem.world:check(
                        entity,
                        entity.x + entity.collider.offsetx,
                        entity.y + entity.collider.offsety + probe,
                        collisionfilter
                    )
                    for i = 1, glen do
                        if gcols[i].normal.y < -0.5 and gcols[i].other.physics and gcols[i].other.physics.velocity then
                            extraVx = gcols[i].other.physics.velocity.x
                            extraVy = gcols[i].other.physics.velocity.y
                            break
                        end
                    end
                end

                local goalx = entity.x + (vx + extraVx) * dt
                local goaly = entity.y + (vy + extraVy) * dt

                local actualx, actualy, cols, len = WorldSystem.world:move(
                    entity,
                    goalx + entity.collider.offsetx,
                    goaly + entity.collider.offsety,
                    collisionfilter
                )

                for i = 1, len do
                    local col = cols[i]
                    local other = col.other

                    if col.item.events.onCollision then
                        col.item.events.onCollision(col.item, other, dt)
                    end
                    if other.events.onCollision then
                        other.events.onCollision(col.item, other, dt)
                    end

                    if col.type == "slide" or col.type == "touch" then
                        if col.normal.y < -0.5 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = 0
                            end
                        elseif col.normal.y > 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = 0
                            end
                        end

                        if col.normal.x ~= 0 then
                            if not isKinematic then
                                if entity.physics and entity.physics.velocity then
                                    entity.physics.velocity.x = 0
                                end
                            elseif isKinematic and col.other.physics.bodytype == "Dynamic" then
                                col.other.physics.velocity.x = entity.physics.velocity.x
                            end
                        end

                    elseif col.type == "bounce" then
                        if col.normal.y ~= 0 then
                            if entity.physics and entity.physics.velocity
                            and entity.physics.velocity.y * col.normal.y < 0 then
                                entity.physics.velocity.y = -entity.physics.velocity.y
                            end
                        end

                        if col.normal.x ~= 0 and entity.physics and entity.physics.velocity then
                            if not isKinematic then

                                local otherIsKinematic = col.other.physics and col.other.physics.bodytype == "Kinematic"
                                local selfdir, otherdir = checkdir(entity, col.other)

                                if (not otherIsKinematic or
                                    selfdir == otherdir)
                                and entity.physics.velocity.x * col.normal.x < 0 then
                                    entity.physics.velocity.x = -entity.physics.velocity.x
                                end

                            elseif isKinematic and col.other.physics and col.other.physics.bodytype == "Dynamic" then

                                local selfdir, otherdir = checkdir(entity, col.other)
                                if otherdir ~= selfdir or col.other.physics.velocity.x < entity.physics.velocity.x then
                                    if entity.physics.velocity.x * col.normal.x < 0 then
                                        if col.other.physics.velocity.x * col.normal.x > 0 then
                                            if col.other.physics.velocity.x > entity.physics.velocity.x then
                                                col.other.physics.velocity.x = -col.other.physics.velocity.x
                                            else
                                                col.other.physics.velocity.x = -col.other.physics.velocity.x + (entity.physics.velocity.x * 1.5)
                                            end
                                        else
                                            col.other.physics.velocity.x = entity.physics.velocity.x * 1.5
                                        end
                                    end

                                end
                            end
                        end
                    end

                    if col.type ~= "cross" and col.item.physics and other.physics then
                        local physicssystem = require(BASE .. "src.PhysicsSystem")
                        local mu = math.sqrt(col.item.physics.frictionScale * other.physics.frictionScale) * physicssystem.worldfriction
                        local mass = col.item.physics.mass or 1.0
                        local gravity = physicssystem.worldgravity
                        local normalForce = mass * gravity
                        local maxFrictionForce = mu * normalForce
                        local maxVelocityDrop = maxFrictionForce * dt / mass
                        local ivx = col.item.physics.velocity.x
                        local ivy = col.item.physics.velocity.y
                        local nx, ny = col.normal.x, col.normal.y
                        local tx, ty = -ny, nx
                        local vn = ivx * nx + ivy * ny
                        local vt = ivx * tx + ivy * ty

                        if math.abs(vt) > 0.001 then
                            local speedLoss = math.min(maxVelocityDrop, math.abs(vt))
                            local newVt = vt - speedLoss * (vt >= 0 and 1 or -1)
                            col.item.physics.velocity.x = vn * nx + newVt * tx
                            col.item.physics.velocity.y = vn * ny + newVt * ty
                        end
                    end
                end

                entity.x = actualx - entity.collider.offsetx
                entity.y = actualy - entity.collider.offsety

                if isDynamic and entity.physics.grounded ~= nil then
                    local probe = 2
                    local _, _, pcols, plen = WorldSystem.world:check(
                        entity,
                        entity.x + entity.collider.offsetx,
                        entity.y + entity.collider.offsety + probe,
                        collisionfilter
                    )
                    local nowGrounded = false
                    for i = 1, plen do
                        if pcols[i].normal.y < -0.5 then
                            nowGrounded = true
                            break
                        end
                    end
                    entity.physics.grounded = nowGrounded

                    if nowGrounded then
                        entity:cancelTimer("coyoteTimer")
                    elseif wasGrounded then
                        entity:after(0.1, function(e)
                            if e.physics then
                                e.physics.grounded = false
                            end
                        end, "coyoteTimer")
                    end
                end

            else
                entity.x = entity.x + vx * dt
                entity.y = entity.y + vy * dt
            end

            ::continue::
        else
            if entity.physics then
                if entity.physics.velocity then
                    entity.x = entity.x + entity.physics.velocity.x * dt
                    entity.y = entity.y + entity.physics.velocity.y * dt
                end
            end
        end
    end
end

return WorldSystem