local BASE = (...) .. "."
local bump = require(BASE .. "libs.bump")
local timer = require(BASE .. "libs.hump.timer")

local WorldSystem = {}

WorldSystem.world = nil

local function collisionfilter(entity, other)
    local entityFilter = entity.collider.collisionfilter or "slide"
    local otherFilter = other.collider.collisionfilter or "slide"

    if entityFilter == "touch" or otherFilter == "touch" then
        return "touch"
    elseif entityFilter == "bounce" or otherFilter == "bounce" then
        return "bounce"
    elseif entityFilter == "slide" or otherFilter == "slide" then
        return "slide"
    end

    return entityFilter
end

function WorldSystem.initworld(cellsize, worldpack)
    local ECS = require(BASE .. "src.EntityComponentSystem")
    WorldSystem.world = bump.newWorld(cellsize or 64)
    if worldpack then
        for _, structures in pairs(worldpack) do
            ECS.register(structures)
        end
    end
end

function WorldSystem.deleteworld()
    WorldSystem.world = nil
end

function WorldSystem.addtoworld(entitylist)
    if WorldSystem.world ~= nil then
        for _, entity in pairs(entitylist) do
            if entity.collider then
                if entity.collider.collision then
                    WorldSystem.world:add(
                        entity,
                        entity.x + entity.collider.offsetx,
                        entity.y + entity.collider.offsety,
                        entity.collider.width,
                        entity.collider.height
                    )
                end
                if (entity.collider.collision == false or entity.collider.collision == nil) and WorldSystem.world:hasItem(entity) then
                    WorldSystem.world:remove(entity)
                end
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
        if WorldSystem.world ~= nil then
            -- Support both old and new velocity style during transition
            local vx = entity.physics and entity.physics.velocity and entity.physics.velocity.x
            local vy = entity.physics and entity.physics.velocity and entity.physics.velocity.y

            if vx == nil or vy == nil then
                goto continue
            end

            local isDynamic = not entity.physics or entity.physics.bodytype == "Dynamic"
            local isKinematic = entity.physics and entity.physics.bodytype == "Kinematic"
            local isStatic = entity.physics and entity.physics.bodytype == "Static"
            local anchored = entity.physics and entity.physics.anchored

            if isStatic or anchored then
                goto continue
            end

            if entity.collider and entity.collider.collision and WorldSystem.world:hasItem(entity) and not entity.physics.anchored then
                if entity.physics.grounded ~= nil then
                    local wasGrounded = entity.physics.grounded
                    entity.physics.grounded = false
                end

                local goalx = entity.x + vx * dt
                local goaly = entity.y + vy * dt

                local actualx, actualy, cols, len = WorldSystem.world:move(
                    entity,
                    goalx + entity.collider.offsetx,
                    goaly + entity.collider.offsety,
                    collisionfilter
                )

                for i = 1, len do
                    local col = cols[i]
                    local other = col.other

                    if entity.events.onCollision then
                        entity.events.onCollision(col.item, other, dt)
                    end
                    if other.events.onCollision then
                        other.events.onCollision(col.item, other,dt)
                    end

                    if isDynamic and other.physics and other.physics.bodytype == "Kinematic" then
                        local otherVel = other.physics.velocity
                        if otherVel then
                            if col.normal.y < -0.5 then
                                if entity.physics and entity.physics.velocity then
                                    entity.physics.velocity.x = otherVel.x
                                    entity.physics.velocity.y = otherVel.y
                                    if entity.physics.grounded ~= nil then
                                        entity.physics.grounded = true
                                    end
                                    if entity.physics.coyoteTimer then
                                        timer.cancel(entity.physics.coyoteTimer)
                                        entity.physics.coyoteTimer = nil
                                    end
                                end
                            end
                        end
                    end

                    if col.type == "slide" or col.type == "touch" then
                        if col.normal.y < 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = 0
                                if entity.physics.grounded ~= nil then
                                    entity.physics.grounded = true
                                end
                            end
                        elseif col.normal.y > 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = 0
                            end
                        end

                        if col.normal.x ~= 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.x = 0
                            end
                        end

                    elseif col.type == "bounce" then
                        if col.normal.y < 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = -entity.physics.velocity.y
                                if entity.physics.grounded ~= nil then
                                    entity.physics.grounded = true
                                end
                            end
                        elseif col.normal.y > 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.y = -entity.physics.velocity.y
                            end
                        end

                        if col.normal.x ~= 0 then
                            if entity.physics and entity.physics.velocity then
                                entity.physics.velocity.x = -entity.physics.velocity.x
                            end
                        end
                    end

                     if col.type ~= "cross" then
                        local physicssystem = require(BASE .. "src.PhysicsSystem")
                        local combinedFriction = math.sqrt(col.item.physics.frictionScale * other.physics.frictionScale)
                        local frictionDamping = 1
                        frictionDamping = math.max(0, 1 - (physicssystem.worldfriction * (combinedFriction) * dt))
                        col.item.physics.velocity.x = col.item.physics.velocity.x * frictionDamping
                        col.item.physics.velocity.y = col.item.physics.velocity.y * frictionDamping
                    end
                end

                if wasGrounded and not entity.physics.grounded then
                    entity.physics.coyoteTimer = timer.after(0.1, function()
                        if entity.physics then
                            entity.physics.grounded = false
                            entity.physics.coyoteTimer = nil
                        end
                    end)
                end
                entity.x = actualx - entity.collider.offsetx
                entity.y = actualy - entity.collider.offsety

            else
                entity.x = entity.x + vx * dt
                entity.y = entity.y + vy * dt
            end

            ::continue::
        else
            if entity.physics.velocity then
                entity.x = entity.x + entity.physics.velocity.x * dt
                entity.y = entity.y + entity.physics.velocity.y * dt
            end
        end
    end
end

return WorldSystem