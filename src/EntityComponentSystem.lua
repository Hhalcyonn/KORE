local BASE = "KORE."
local ECS = {}
local entitymethods = require(BASE .. "src.EntityMethods")
local timer = require(BASE .. "libs.hump.timer")
local assets = require(BASE .."src.AssetsSystem")
local log = require(BASE .. "src.log")
local WorldSystem = require(BASE .. "src.WorldSystem")

ECS.__index = ECS
ECS.entities = {}
ECS.nextId = 1

local function createId()
    local id = ECS.nextId
    ECS.nextId = ECS.nextId + 1
    return id
end

function ECS:setID(num)
    if num then
        ECS.nextId = num
        log.info("ECS next ID is set to: " .. tostring(ECS.nextId))
    end
end

function ECS.register(entity)
    local id = entity.identity.id
    if id == nil then
        id = createId()
        entity.identity.id = id
    end
    ECS.entities[id] = entity
    WorldSystem.addtoworld(ECS.entities[id])
end

function ECS.removeentity(entity)
    ECS.entities[entity.identity.id] = nil
end

function ECS.removeDeadEntities()
    for id, entity in pairs(ECS.entities) do
        if not entity.alive then

            entity.collider.collision = false
            WorldSystem.removefromworld(entity)
            if entity.timers then
                for handle in pairs(entity.timers) do
                    timer.cancel(handle)
                end
                entity.timers = {}
            end
            ECS.removeentity(entity)

        end
    end
end

function ECS.splitname(name)
    local basename, number = name:match("^(.-)_(%d+)$")

    if basename then
        return basename, tonumber(number)
    end

    return name, nil
end

local function registername(name)
    local counter = 0
    local resultname = name
    while true do
        local exists = false
        for _, entity in pairs(ECS.entities) do
            if entity.identity.name == resultname then
                exists = true
                break
            end
        end
        if not exists then
            return resultname
        end
        counter = counter + 1
        resultname = name .. "_" .. counter
    end
end

function ECS.clearAllentities()
    local count = 0

    for _, entity in pairs(ECS.entities) do
        entity.alive = false
        count = count + 1
    end

    log.info("clearAllentities was called. Marked " .. count .. " entities for removal")
end

function ECS.getEntityByIdentity(arg, arg2)
    if not arg or not arg2 then return nil end
    
    local search_type = string.lower(tostring(arg))

    if search_type == "id" then
        local id_num = tonumber(arg2)
        return ECS.entities[id_num] 
    end

    local batch = {}
    for _, entity in pairs(ECS.entities) do
        if entity.identity then
            if search_type == "name" and entity.identity.name == tostring(arg2) then
                return entity
            elseif search_type == "tag" and entity.identity.tags and entity.identity.tags[tostring(arg2)] then
                batch[entity.identity.id] = entity
            end
        end
    end
    local count = 0
    for value, key in next, batch, nil do
        count = count + 1
    end
    if count ~= 0 then return batch end
    return nil
end

local Entity = {}
Entity.__index = Entity
for name, method in pairs(entitymethods) do
    Entity[name] = method
end
function ECS.createentity(data)
    local entity = setmetatable({}, Entity)
    local config = require(BASE .. "config").PhysicsSystem

    entity.alive = true

    entity.identity = {
        name = registername(data and data.name or "unnamedentity"),
        id = createId(),
        tags = data and data.tags or {}
    }

    entity.state = data and data.state or "idle"

    entity.x = data and data.x or 0
    entity.y = data and data.y or 0
    entity.facing = data and data.facing or 1

    if data and data.lifetime then
        entity.lifetime = data and data.lifetime
    end

    if data and data.physics then
        if config.physics_mode == "advanced" then
            if data.physics.bodytype == "Dynamic" then
                entity.physics = {
                    bodytype = "Dynamic",
                    velocity = {x = 0, y = 0},
                    force = {x = 0, y = 0},
                    mass = data.physics.mass or 1,
                    gravityScale = data.physics.gravityScale or 1,
                    dragScale = data.physics.dragScale or 1,
                    frictionScale = data.physics.frictionScale or 1,
                    grounded = false,
                    anchored = data.physics.anchored or false,
                }
            elseif data.physics.bodytype == "Kinematic" then
                entity.physics = {
                    bodytype = "Kinematic",
                    velocity = {x = data.physics.velocity and data.physics.velocity.x or 0, y = data.physics.velocity and data.physics.velocity.y or 0},
                    anchored = data.physics.anchored or false,
                    frictionScale = data.physics.frictionScale or 1
                }
            elseif data.physics.bodytype == "Static" then
                entity.physics = {
                    bodytype = "Static",
                    anchored = true,
                    frictionScale = data.physics.frictionScale or 1
                }
            else
                log.warn(
                    "Unknown physics bodytype '" ..
                    tostring(data.physics.bodytype) ..
                    "' for entity '" ..
                    tostring(data.identity and data.identity.name or entity.identity.id) ..
                    "'. Force fallback to Static."
                )
                entity:setBodytype({bodytype = "Static"})
            end
        elseif config.physics_mode == "simple" then
            entity.physics = {
                velocity = {x = 0, y = 0},
                gravity = data.physics.gravity or 400,
                drag = data.physics.drag or 300,
                grounded = false,
                anchored = data.physics.anchored or false,
                overSpeedMode = data.physics.overSpeedMode or "clamp"
            }
        end
    end

    if data and data.health then
        entity.health = {
            current = data and data.health.current or 100,
            max = data and data.health.max or 100,
            dying = false,
            dyingduration = data and data.health.dyingduration or 0,
        }
    end

    if data and data.input then
        entity.input = data and data.input
    end

    if data and data.sprite then
        entity.sprite = {
            type = "image",
            image = assets.images[ data and data.sprite]
        }
    end

    if data and data.animationpack then
        entity.animations = assets.loadpack(
            data and data.animationpack,
            "anim8anim"
        )
        entity.animdata = {
            current = nil
        }
    end

    entity.events = {
        beforeupdanim = data and data.events and data.events.beforeupdanim or function() end,
        behavior = data and data.events and data.events.behavior or function() end,
        controller = data and data.events and data.events.controller or function() end,
        onMousePressed = data and data.events and data.events.onMousePressed or function() end,
        onKeyReleased = data and data.events and data.events.onKeyReleased or function() end,
        onKeyPressed = data and data.events and data.events.onKeyPressed or function() end,
        onDeath = data and data.events and data.events.onDeath or function() end,
        onCollision = data and data.events and data.events.onCollision or function() end
    }

    entity.timers = {}

    entity.customkeys =  data and data.customkeys or {}

    entity.collider = {}

    entity.collider.collision =
        data and data.collider and data.collider.collision ~= nil and data.collider.collision or true

    entity.collider.collisionfilter =
        data and data.collider and data.collider.collisionfilter or "slide"

    entity.collider.priority =
        data and data.collider and data.collider.priority or "1"

    entity.collider.offsetx =
        data and data.collider and data.collider.offsetx or 0

    entity.collider.offsety =
        data and data.collider and data.collider.offsety or 0

    entity.collider.width =
        data and data.collider and data.collider.width or (entity.sprite and entity.sprite.image:getWidth() or 50)

    entity.collider.height =
        data and data.collider and data.collider.height or (entity.sprite and entity.sprite.image:getHeight() or 50)


    entity.drawdata = {}

    entity.drawdata.drawable =
        data and data.drawdata and data.drawdata.drawable ~= nil and data.drawdata.drawable or true

    entity.drawdata.width =
        data and data.drawdata and data.drawdata.width or (entity.sprite and entity.sprite.image:getWidth() or 50)

    entity.drawdata.height =
        data and data.drawdata and data.drawdata.height or (entity.sprite and entity.sprite.image:getHeight() or 50)

    entity.drawdata.r =
        data and data.drawdata and data.drawdata.r or 0

    entity.drawdata.sx =
        data and data.drawdata and data.drawdata.sx or entity.facing

    entity.drawdata.sy =
        data and data.drawdata and data.drawdata.sy or 1

    entity.drawdata.ox =
        ddata and data.drawdata and data.drawdata.ox or (entity.drawdata.width / 2)
    entity.drawdata.oy =
        data and data.drawdata and data.drawdata.oy or (entity.drawdata.height / 2)

    entity.drawdata.kx =
        data and data.drawdata and data.drawdata.kx or 0
    entity.drawdata.ky =
        data and data.drawdata and data.drawdata.ky or 0

    entity.drawdata.layer =
        data and data.drawdata and data.drawdata.layer or "world"

    return entity
end

function ECS.onKeyPressed(key, entity)
    if entity.events.onKeyPressed then
        entity.events.onKeyPressed(key, entity)
    end
end

function ECS.onMousePressed(x, y, button, entity)
    if entity.events.onMousePressed then
        entity.events.onMousePressed(x, y, button, entity)
    end
end

function ECS.onKeyReleased(key, entity)
    if entity.events.onKeyReleased then
        entity.events.onKeyReleased(key, entity)
    end
end

function ECS.update(dt, entity)

    if entity.animations and entity.state then
        local anim = entity.animations[entity.animdata.current]
        if anim then
            if entity.events and entity.events.beforeupdanim then
                entity.events.beforeupdanim(entity, dt)
            end

            local animObj = anim.animation or anim
            if animObj and animObj.update then
                anim.previousframe = animObj.position
                
                animObj:update(dt)
            end
        end
    end

    if entity.physics and not entity.physics.anchored then
        if entity.events.controller then
            entity.events.controller(entity, dt)
        end
    end

    if entity.events.behavior then
        entity.events.behavior(entity, dt)
    end

    if entity.lifetime then
        if entity.lifetime <= 0 then
            entity.alive = false
            return
        end
        entity.lifetime = entity.lifetime - dt
    end

    if entity.health and entity.health.current <= 0 and not entity.health.dying then
        entity.health.dying = true
        if entity.events.onDeath then
            entity.events.onDeath(entity, dt)
        end
        entity:after(entity.health.dyingduration or 0, function()
            if entity.health.dying then
                entity.alive = false
            end
        end)
    end
end

return ECS