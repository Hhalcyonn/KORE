local BASE = "KORE."
local bump = require(BASE .. "libs.bump")
local log = require(BASE .. "src.log")
local config = require(BASE .. "config").PhysicsSystem
-- god fucking help me please im so tired of this shit
local WorldSystem = {}
WorldSystem.contacts = {}

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

local function kinematicMoverFilter(entity, other)
    local r = collisionfilter(entity, other)
    if r == "bounce" then return "slide" end
    return r
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

local function kinematicBounce(kinVel, dynVel, normal, e)
    if e == nil or e < 0 or e > 1 then
        e = 1
    end

    local kinNormal = vecDot(kinVel, normal)
    local dynNormal = vecDot(dynVel, normal)

    local newNormal = (1 + e) * kinNormal - e * dynNormal

    local dynTangent = {
        x = dynVel.x - normal.x * dynNormal,
        y = dynVel.y - normal.y * dynNormal
    }

    return {
        x = dynTangent.x + normal.x * newNormal,
        y = dynTangent.y + normal.y * newNormal
    }
end

local function pushDynamics(goalx, goaly, actualx, actualy, cols, len)
    local sx, sy = goalx - actualx, goaly - actualy
    local pushed = false

    for i = 1, len do
        local col = cols[i]
        local kin, other = col.item, col.other
        local otherIsDynamic = checkbodytype(other)

        if otherIsDynamic and other.collider and not other.physics.anchored
           and (col.type == "slide" or col.type == "touch") then
            local nx, ny = col.normal.x, col.normal.y
            local into = -(sx * nx + sy * ny)
            if into > 0 then
                local c = other.collider
                local ax, ay = WorldSystem.world:move(
                    other,
                    other.x + c.offsetx - nx * into,
                    other.y + c.offsety - ny * into,
                    collisionfilter)
                other.x, other.y = ax - c.offsetx, ay - c.offsety
                pushed = true

                -- the dynamic's own filter decides how it reacts
                if collisionfilter(other, kin) == "bounce" then
                    local nv = kinematicBounce(kin.physics.velocity, other.physics.velocity, col.normal, 1)
                    other.physics.velocity.x, other.physics.velocity.y = nv.x, nv.y
                end
            end
        end
    end

    return pushed
end

local function resolveImpact(col)
    local e1 = col.item
    local e2 = col.other

    if not e1.physics then return end
    if not e2.physics or not e2.physics.velocity then return end

    local isDynamic, isKinematic, isStatic = checkbodytype(e1)
    local otherisDynamic, otherisKinematic, otherisStatic = checkbodytype(e2)

    if isStatic then
        return
    end

    if isDynamic and otherisDynamic then
        local v1, v2 = elasticCollision(
            e1,
            e2,
            col.normal,
            0.5
        )

        e1.physics.velocity.x = v1.x
        e1.physics.velocity.y = v1.y

        e2.physics.velocity.x = v2.x
        e2.physics.velocity.y = v2.y

        return
    end
    if col.type == "bounce" then
        if (isDynamic and otherisKinematic) or
           (isKinematic and otherisDynamic) then

            local kin, dyn

            if isDynamic and otherisKinematic then
                kin = e2
                dyn = e1
            else
                kin = e1
                dyn = e2
            end

            local kinVel = kin.physics.velocity
            local dynVel = dyn.physics.velocity

            local relativeVelocity = {
                x = dynVel.x - kinVel.x,
                y = dynVel.y - kinVel.y
            }

            local closing = vecDot(
                relativeVelocity,
                col.normal
            )

            if closing < 0 then
                local newVelocity = kinematicBounce(
                    kinVel,
                    dynVel,
                    col.normal,
                    1
                )

                dyn.physics.velocity.x = newVelocity.x
                dyn.physics.velocity.y = newVelocity.y
            end
        end
    end
end

local function resolveContact(col)
    local e1 = col.item
    local e2 = col.other

    if not e1.physics then return end

    local isDynamic, isKinematic, isStatic = checkbodytype(e1)

    if not e2.physics or not e2.physics.velocity then
        if col.type == "slide" or col.type == "touch" then
            local v = e1.physics.velocity
            local nx, ny = col.normal.x, col.normal.y
            local vn = v.x * nx + v.y * ny

            v.x = v.x - nx * vn
            v.y = v.y - ny * vn
        end

        return
    end

    local otherisDynamic, otherisKinematic, otherisStatic = checkbodytype(e2)

    if isStatic then
        return
    end

    if col.type ~= "slide" and col.type ~= "touch" then
        return
    end

    local nx, ny = col.normal.x, col.normal.y

    if otherisStatic then
        local v = e1.physics.velocity
        local vn = v.x * nx + v.y * ny

        v.x = v.x - nx * vn
        v.y = v.y - ny * vn
        return
    end
    if isDynamic and otherisDynamic then
        if math.abs(ny) > 0.7 then
            local top, bottom
            if ny < 0 then top, bottom = e1, e2 else top, bottom = e2, e1 end
            local tv, bv = top.physics.velocity, bottom.physics.velocity
            if tv.y > bv.y then
                tv.y = bv.y
            end
        else
            local v1, v2 = elasticCollision(e1, e2, col.normal, 0)
            e1.physics.velocity.x, e1.physics.velocity.y = v1.x, v1.y
            e2.physics.velocity.x, e2.physics.velocity.y = v2.x, v2.y
        end
    end
    if (isDynamic and otherisKinematic) or
       (isKinematic and otherisDynamic) then

        local kin, dyn

        if isDynamic then
            kin = e2
            dyn = e1
        else
            kin = e1
            dyn = e2
        end

        local kinVel = kin.physics.velocity
        local dynVel = dyn.physics.velocity

        local kinNormal = kinVel.x * nx + kinVel.y * ny
        local dynNormal = dynVel.x * nx + dynVel.y * ny

        local normalDelta = dynNormal - kinNormal

        dynVel.x = dynVel.x - nx * normalDelta
        dynVel.y = dynVel.y - ny * normalDelta
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

local SUPPORT_PROBE = 0.5

local function findSupport(entity)
    local c = entity.collider
    if not (c and c.collision and WorldSystem.world:hasItem(entity)) then return nil end
    local _, _, cols, len = WorldSystem.world:check(
        entity,
        entity.x + c.offsetx,
        entity.y + c.offsety + SUPPORT_PROBE,
        collisionfilter
    )
    for i = 1, len do
        if cols[i].normal.y < -0.5 and cols[i].type ~= "cross" then
            return cols[i].other
        end
    end
    return nil
end

local function carrier(entity, depth)
    local s = findSupport(entity)
    if not s then return nil end

    local p = s.physics
    if not p or not p.velocity or p.bodytype == "Static" then return 0, 0 end

    if p.bodytype == "Kinematic" then
        return p.velocity.x, p.velocity.y
    end

    if depth < 8 then
        local bx, by = carrier(s, depth + 1)
        if by then return bx, by end
    end
    return 0, p.velocity.y
end

function WorldSystem.update(entitylist, dt)
    local ordered = {}
    for _, e in pairs(entitylist) do ordered[#ordered + 1] = e end
    table.sort(ordered, function(a, b)
            local pa = a.collider and tonumber(a.collider.priority) or 1
            local pb = b.collider and tonumber(b.collider.priority) or 1
            if pa ~= pb then return pa < pb end

            local ka = (a.physics and a.physics.bodytype == "Kinematic") == true
            local kb = (b.physics and b.physics.bodytype == "Kinematic") == true
            if ka ~= kb then return kb end

            if a.y ~= b.y then return a.y < b.y end
            return a.identity.id < b.identity.id
        end)

    local resolvedPairs = {}
    local currentContacts = {}

    for _, entity in ipairs(ordered) do
        if WorldSystem.world ~= nil then

            local vx = entity.physics and entity.physics.velocity and entity.physics.velocity.x
            local vy = entity.physics and entity.physics.velocity and entity.physics.velocity.y

            if vx == nil or vy == nil or entity.physics.anchored then
                goto continue
            end

            local isDynamic = not entity.physics or entity.physics.bodytype == "Dynamic"
            local isStatic = entity.physics and entity.physics.bodytype == "Static"

            if isStatic then
                goto continue
            end

            if entity.collider and entity.collider.collision and WorldSystem.world:hasItem(entity) then

                local extraX = 0
                if isDynamic then
                    local cx, cy = carrier(entity, 0)
                    if cy then
                        if entity.physics.velocity.y > cy then
                            entity.physics.velocity.y = cy
                        end
                        extraX = cx
                    end
                end

                local goalx = entity.x + (entity.physics.velocity.x + extraX) * dt
                local goaly = entity.y + entity.physics.velocity.y * dt

                local gx = goalx + entity.collider.offsetx
                local gy = goaly + entity.collider.offsety

                local moveFilter = (entity.physics.bodytype == "Kinematic") and kinematicMoverFilter or collisionfilter
                local actualx, actualy, cols, len = WorldSystem.world:move(entity, gx, gy, moveFilter)

                if entity.physics.bodytype == "Kinematic"
                and pushDynamics(gx, gy, actualx, actualy, cols, len) then
                    actualx, actualy, cols, len = WorldSystem.world:move(entity, gx, gy, moveFilter)
                end

                local iteration = 4
                for _ = 1, iteration do

                    if len == 0 then break end
                    
                    for i = 1, len do
                        local col = cols[i]
                        local key = pairKey(col.item, col.other)
                        local wasInContact = WorldSystem.contacts[key] ~= nil
                        currentContacts[key] = col

                        if not resolvedPairs[key] then
                            resolvedPairs[key] = true

                            if wasInContact then
                                resolveContact(col)
                            else
                                resolveImpact(col)
                            end

                            if col.item.events.onCollision then
                                col.item.events.onCollision(col, dt)
                            end

                            if col.other.events.onCollision then
                                col.other.events.onCollision(col, dt)
                            end
                        end

                        if col.type ~= "cross" and col.item.physics and col.other.physics then
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
                end

                entity.x = actualx - entity.collider.offsetx
                entity.y = actualy - entity.collider.offsety

            else
                entity.x = entity.x + vx * dt
                entity.y = entity.y + vy * dt
            end

            ::continue::
        else
            if entity.physics and entity.physics.velocity then
                entity.x = entity.x + entity.physics.velocity.x * dt
                entity.y = entity.y + entity.physics.velocity.y * dt
            end
        end
    end

    if WorldSystem.world ~= nil then
        for _, entity in ipairs(ordered) do
            local p = entity.physics
            local c = entity.collider
            if p and p.grounded ~= nil and p.bodytype == "Dynamic" and not p.anchored
               and c and c.collision and WorldSystem.world:hasItem(entity) then
                local wasGrounded = p.grounded
                local _, _, pcols, plen = WorldSystem.world:check(
                    entity,
                    entity.x + c.offsetx,
                    entity.y + c.offsety + 2,
                    collisionfilter
                )
                local nowGrounded = false
                for i = 1, plen do
                    if pcols[i].normal.y < -0.5 then
                        nowGrounded = true
                        break
                    end
                end
                p.grounded = nowGrounded

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
        end
    end

    WorldSystem.contacts = currentContacts
end

return WorldSystem