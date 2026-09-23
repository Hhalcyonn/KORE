local BASE = "KORE."
local bump = require(BASE .. "libs.bump")
local log = require(BASE .. "src.log")
local config = require(BASE .. "config").PhysicsSystem

local WorldSystem = {}

local function pairKey(a, b)
    if tostring(a) < tostring(b) then
        return tostring(a) .. "|" .. tostring(b)
    else
        return tostring(b) .. "|" .. tostring(a)
    end
end

WorldSystem.world = nil

local function vecDot(a, b)
    return a.x * b.x + a.y * b.y
end

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

local function checkbodytype(e)
    local body = e.physics and e.physics.bodytype
    local isDynamic = false
    local isStatic = false
    local isKinematic = false

    if body == "Kinematic" then
        isKinematic = true
    elseif body == "Dynamic" then
        isDynamic = true
    elseif body == "Static" then
        isStatic = true
    end

    return isDynamic, isKinematic, isStatic
end

local function checkdirX(item, other)
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

local function checkdirY(item, other)
    local selfdir, otherdir
    if item.physics.velocity.y > 0 then selfdir = 1
    elseif item.physics.velocity.y < 0 then selfdir = -1 end
    if other.physics.velocity.y > 0 then otherdir = 1
    elseif other.physics.velocity.y < 0 then otherdir = -1 end
    return selfdir, otherdir
end

local function elasticCollision(e1, e2, normal, e) 
    local p1 = e1.physics
    local p2 = e2.physics
    local v1 = p1.velocity
    local v2 = p2.velocity
    local m1 = p1.mass
    local m2 = p2.mass
    if e == nil or e < -1 or e > 1 then
        e = 0.5
    end

    local vn1 = vecDot(v1, normal)
    local vt1 = {x = v1.x - normal.x * vn1, y = v1.y - normal.y * vn1}

    local vn2 = vecDot(v2, normal)
    local vt2 = {x = v2.x - normal.x * vn2, y = v2.y - normal.y * vn2}

    local totalMass = m1 + m2
    local newVn1 = ((m1 - e*m2) * vn1 + (1 + e) * m2 * vn2) / totalMass
    local newVn2 = ((m2 - e*m1) * vn2 + (1 + e) * m1 * vn1) / totalMass

    local newV1 = {x = vt1.x + normal.x * newVn1, y = vt1.y + normal.y * newVn1}
    local newV2 = {x = vt2.x + normal.x * newVn2, y = vt2.y + normal.y * newVn2}

    return newV1, newV2
end


local function resolve(col)
    local e1 = col.item
    local e2 = col.other
    local function resolver()
    if col.normal.x ~= 0 then
        if col.type == "bounce" then
            e1.physics.velocity.x = -e1.physics.velocity.x
        elseif col.type == "slide" or col.type == "touch" then
            e1.physics.velocity.x = 0
        end
    end
    if col.normal.y ~= 0 then
        if col.type == "bounce" then
            e1.physics.velocity.y = -e1.physics.velocity.y
        elseif col.type == "slide" or col.type == "touch" then
            e1.physics.velocity.y = 0
        end
    end
end
    if not e1.physics then return end
    if not e2.physics or not 
        e2.physics.velocity then resolver() return end

    local isDynamic, isKinematic, isStatic = checkbodytype(e1)
    local otherisDynamic, otherisKinematic, otherisStatic = checkbodytype(e2)
    if otherisStatic then
        resolver()
        return
    elseif isStatic then
        return
    end
    local selfdirx, otherdirx = checkdirX(col.item, col.other)
    local selfdiry, otherdiry = checkdirY(col.item, col.other)
    if col.type == "slide" or col.type == "touch" then

    if col.normal.y < -0.5 then -- ontop
        if isKinematic and otherisDynamic then
            e2.physics.velocity.y = entity.physics.velocity.y
        elseif otherisKinematic then
            e1.physics.velocity.y = e2.physics.velocity.y
        elseif isDynamic and otherisDynamic then
            local v1, v2 = elasticCollision(e1, e2, col.normal, 0.5)
            e1.physics.velocity = v1
            e2.physics.velocity = v2
        end
    elseif col.normal.y > 0 then -- below
        if isKinematic and otherisDynamic then
            e2.physics.velocity.y = e1.physics.velocity.y
        elseif otherisKinematic then
            e1.physics.velocity.y = e2.physics.velocity.y
        elseif isDynamic and otherisDynamic then
            local v1, v2 = elasticCollision(e1, e2, col.normal, 0.5)
            e1.physics.velocity = v1
            e2.physics.velocity = v2
        end
    end
        
        if col.normal.x ~= 0 then -- sides
            if isDynamic and otherisDynamic then
                local v1, v2 = elasticCollision(e1, e2, col.normal, 1)
                e1.physics.velocity = v1
                e2.physics.velocity = v2
            elseif isKinematic and otherisDynamic then
                e2.physics.velocity.x = e1.physics.velocity.x
            end
        end
        
    elseif col.type == "bounce" then
        if col.normal.y ~= 0 then
            if isDynamic and otherisDynamic then
                local v1, v2 = elasticCollision(e1, e2, col.normal, 0.5)
                e1.physics.velocity = v1
                e2.physics.velocity = v2
            elseif e1.physics.velocity.y * col.normal.y < 0 then
                e1.physics.velocity.y = -e1.physics.velocity.y
            end
        end

        if col.normal.x ~= 0 then
            if isDynamic and otherisDynamic then
                local v1, v2 = elasticCollision(e1, e2, col.normal, 0.5)
                e1.physics.velocity = v1
                e2.physics.velocity = v2
            elseif not isKinematic then
                local selfdir, otherdir = checkdir(e1, e2)
                if (not otherisKinematic or selfdir == otherdir)
                    and e1.physics.velocity.x * col.normal.x < 0 then
                    e1.physics.velocity.x = -e1.physics.velocity.x
                elseif isKinematic and otherisDynamic then
                    if otherdir ~= selfdir or e2.physics.velocity.x < e1.physics.velocity.x then
                        if e1.physics.velocity.x * col.normal.x < 0 then
                            if e2.physics.velocity.x * col.normal.x > 0 then
                                if e2.physics.velocity.x > e1.physics.velocity.x then
                                    e2.physics.velocity.x = -e2.physics.velocity.x
                                else
                                    e2.physics.velocity.x = -e2.physics.velocity.x + (e1.physics.velocity.x * 1.5)
                                end
                            else
                                e2.physics.velocity.x = e1.physics.velocity.x * 1.5
                            end
                        end
                    end
                end
            end
        end
    end
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
    local resolvedPairs = {}
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

                local groundEntity = nil
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
                            groundEntity = gcols[i].other
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
                    local key = pairKey(col.item, col.other)

                    if not resolvedPairs[key] then
                        resolvedPairs[key] = true
                        resolve(col)
                        if col.item.events.onCollision then
                        col.item.events.onCollision(col, dt)
                        end
                        if col.other.events.onCollision then
                            col.other.events.onCollision(col, dt)
                        end
                    end


                    if col.type ~= "cross" and col.item.physics and col.physics then
                        local physicssystem = require(BASE .. "src.PhysicsSystem")
                        local mu = math.sqrt(col.item.physics.frictionScale * col.other.physics.frictionScale) * physicssystem.worldfriction
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