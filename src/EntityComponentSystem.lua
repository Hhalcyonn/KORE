local BASE = (...) .. "."
local ECS = {}
local entitymethods = require(BASE .. "src.EntityMethods")
local timer = require(BASE .. "libs.hump.timer")
local assets = require(BASE .."src.AssetsSystem")

ECS.__index = ECS
ECS.entities = {}
ECS.nextId = 1

local function createId()
    local id = ECS.nextId
    ECS.nextId = ECS.nextId + 1
    return id
end

function ECS.register(entity)
    local id = entity.identity.id
    if id == nil then
        id = createId()
        entity.identity.id = id
    end
    ECS.entities[id] = entity
end

function ECS.removeentity(entity)
    ECS.entities[entity.identity.id] = nil
end

function ECS.removeDeadEntities()
    local WorldSystem = require("src/WorldSystem")

    for id, entity in pairs(ECS.entities) do
        if not entity.alive then
            entity.collider.collision = false
            ECS.removeentity(entity)
        end
    end
end

local function ECS.splitname(name)
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

function ECS.getEntityByIdentity(arg, arg2)
    if not arg or not arg2 then return nil end
    
    local search_type = string.lower(tostring(arg))

    if search_type == "id" then
        local id_num = tonumber(arg2)
        return ECS.entities[id_num] 
    end

    -- Loop fallback for names and tags
    for _, entity in pairs(ECS.entities) do
        if entity.identity then
            if search_type == "name" and entity.identity.name == tostring(arg2) then
                return entity
            elseif search_type == "tag" and entity.identity.tags and entity.identity.tags[tostring(arg2)] then
                return entity
            end
        end
    end

    return nil
end

local Entity = {}
Entity.__index = Entity
for name, method in pairs(entitymethods) do
    Entity[name] = method
end
function ECS.createentity(data)
    data = data or {}

    local entity = setmetatable({}, Entity)

    entity.alive = true

    entity.identity = {
        name = registername(data.name or "unnamedentity"),
        id = createId(),
        tags = data.tags or {}
    }

    entity.state = data.state or "idle"

    entity.x = data.x or 0
    entity.y = data.y or 0
    entity.facing = data.facing or 1

    if data.lifetime then
        entity.lifetime = data.lifetime
    end

    if data.physics or (type(data.physics) == boolean and data.physics == true) then
        if data.physics.bodytype == "Dyanmic" then
            entity.physics = {
                bodytype = "Dynamic",
                velocity = {x = 0, y = 0},
                force = {x = 0, y = 0},
                mass = data.physics.mass or 1,
                gravityScale = data.physics.gravityScale or 1,
                dragScale = data.physics.dragScale or 1,
                frictionScale = data.physics.frictionScale or 1,
                maxSpeed = {x = data.physisc.maxSpeed.x or 1000, y = data.physics.maxSpeed.y or 2000}
                grounded = false,
                anchored = data.physics.anchored or false
            }
        elseif data.physics.bodytype == "Kinematic" then
            entity.physics = {
                bodytype = "Kinematic",
                velocity = {x = 0, y = 0},
                maxSpeed = {x = data.physics.maxSpeed.x or 1000, y = data.physics.maxSpeed.y or 2000}
                anchored = data.physics.anchored or false
            }
        elseif data.physics.bodytype == "Static" then
            entity.physics = {
                bodytype = "Static",
                anchored = true
            }
        end
    end

    if data.health then
        entity.health = {
            current = data.health.current or 100,
            max = data.health.max or 100,
            dying = false,
            dyingduration = data.health.dyingduration or 0,
        }
    end

    if data.input then
        entity.input = data.input
    end

    if data.sprite then
        entity.sprite = {
            type = "image",
            image = assets.images[data.sprite]
        }
    end

    if data.animationpack then
        entity.animations = assets.loadpack(
            data.animationpack,
            "anim8anim"
        )
        entity.animdata = {
            current = nil
        }
    end
    entity.events = {
        beforeupdanim = data.events.beforeupdanim,
        behavior = data.events.behavior,
        onMousePressed = data.events.onMousePressed or function() end,
        onKeyReleased = data.events.onKeyReleased or function() end,
        onKeyPressed = data.events.onKeyPressed or function() end,
        onDeath = data.events.onDeath or function() end,
        onCollision = data.events.onCollision or function() end
    }

    entity.customkeys = data.customkeys or {}

    -- Collider
    data.collider = data.collider or {}
    data.drawdata = data.drawdata or {}

    entity.collider = {}

    entity.collider.collision =
        data.collider.collision ~= nil and data.collider.collision or true

    entity.collider.collisionfilter =
        data.collider.collisionfilter or "slide"

    entity.collider.offsetx =
        data.collider.offsetx or 0

    entity.collider.offsety =
        data.collider.offsety or 0

    entity.collider.width =
        data.collider.width or (entity.sprite and entity.sprite.image:getWidth() or 50)

    entity.collider.height =
        data.collider.height or (entity.sprite and entity.sprite.image:getHeight() or 50)


    entity.drawdata = {}

    entity.drawdata.drawable =
        data.drawdata.drawable ~= nil and data.drawdata.drawable or true

    entity.drawdata.width =
        data.drawdata.width or (entity.sprite and entity.sprite.image:getWidth() or 50)

    entity.drawdata.height =
        data.drawdata.height or (entity.sprite and entity.sprite.image:getHeight() or 50)

    entity.drawdata.r =
        data.drawdata.r or 0

    entity.drawdata.sx =
        data.drawdata.sx or entity.facing

    entity.drawdata.sy =
        data.drawdata.sy or 1

    entity.drawdata.ox =
        data.drawdata.ox or (entity.sprite and entity.sprite.image:getWidth() / 2 or 50)
    entity.drawdata.oy =
        data.drawdata.oy or (entity.sprite and entity.sprite.image:getHeight() / 2 or 50)

    entity.drawdata.layer =
        data.drawdata.layer or "world"

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
            -- 1. Store the frame BEFORE advancing time
            anim.previousframe = animObj.position
            
            -- 2. Advance the animation playhead
            animObj:update(dt)
        end
    end
end

    if not entity.anchored then
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
        timer.after(entity.health.dyingduration or 0, function()
            if entity.health.dying then
                entity.alive = false
            end
        end)
    end
end

return ECS