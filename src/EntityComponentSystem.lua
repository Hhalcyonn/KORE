

local ECS = {}
local assetssystem = require("src/AssetsSystem")
local physics = require("src/PhysicsSystem")
local entitymethods = require("src/EntityMethods")
ECS.__index = ECS

ECS.entities = {}
ECS.typebatch = {
    players = {},
    objects = {},
    particles = {},
    npcs = {},
    structures = {}
}
ECS.subtypebatch = {}

function ECS.register(entity)
    table.insert(ECS.entities, entity)
    if entity.type then
        table.insert(ECS.typebatch[entity.type .. "s"], entity)
    end
    if entity.name then
        local name, num = ECS.splitname(entity.name)
        -- Create the batch if it doesn't exist
        if not ECS.subtypebatch[name] then
            ECS.subtypebatch[name] = {}
        end
        table.insert(ECS.subtypebatch[name], entity)
    end
end

function ECS.removeentity(entity)
    for index = #ECS.entities, 1, -1 do
        if ECS.entities[index] == entity then
            table.remove(ECS.entities, index)
            -- Find and remove from typebatch
            if entity.type and ECS.typebatch[entity.type .. "s"] then
                for i = #ECS.typebatch[entity.type .. "s"], 1, -1 do
                    if ECS.typebatch[entity.type .. "s"][i] == entity then
                        table.remove(ECS.typebatch[entity.type .. "s"], i)
                        break
                    end
                end
            end
            -- Find and remove from subtypebatch
            if entity.name then
                local name, num = ECS.splitname(entity.name)
                if ECS.subtypebatch[name] then
                    for i = #ECS.subtypebatch[name], 1, -1 do
                        if ECS.subtypebatch[name][i] == entity then
                            table.remove(ECS.subtypebatch[name], i)
                            break
                        end
                    end
                end
            end
            return
        end
    end
end

function ECS.removeDeadEntities()
    for index = #ECS.entities, 1, -1 do
        local entity = ECS.entities[index]
        local WorldSystem = require("src/WorldSystem")

        if not entity.alive then
            WorldSystem.removefromworld(entity)
            ECS.removeentity(entity)

            -- Cancel entity-specific timers here if you create any.
            entity.controller = nil
            entity.behavior = nil
            entity.animations = nil
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

local Entity = {}
Entity.__index = Entity
for name, method in pairs(entitymethods) do
    Entity[name] = method
end
local function registername(entitylist, name)
    local counter = 0
    local resultname = name
    while true do
        local exists = false
        for _, entity in pairs(entitylist) do
            if entity.name == resultname then
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

function ECS.createstructure(data)
    local structure = setmetatable({}, Entity)

    structure.x = data.x or 0
    structure.y = data.y or 0
    structure.alive = data.alive ~= nil and data.alive or true

    structure.width = data.width or 32
    structure.height = data.height or 32
    structure.facing = data.facing or 1
    structure.animdata = data.animdata or {
        previousframe = 1,
        lastAnimationPosition = 0
    }

    structure.anchored = true

    structure.collision = data.collision
    if structure.collision == nil then
        structure.collision = true
    end
    if data.drawdata ~= nil then
    structure.drawdata = data.drawdata
    else
        structure.drawdata = {
        spritewidth = 94,
        spriteheight = 94,
        r = 0,
        sx = structure.facing,
        sy = 1,
        ox = 94/2,
        oy = 0,
        layer = "background"
        }
    end
    if data.beforeupdanim then
        structure.beforeupdanim = data.beforeupdanim
    end
    if data.name then
        structure.name = registername(ECS.entities, data.name)
    end

    structure.collisionfilter = data.collisionfilter or "slide"
    structure.type = "structure"

    if data.imagesprite then
        structure.image = {image = assetssystem.images[data.imagesprite], type = "image"}
    end

    if data.spritepack then
        structure.animations = assetssystem.loadpack(data.spritepack, "anim8anim")
    end
    structure.state = data.state or "idle"
    if data.collisionlogic ~= nil then structure.collisionlogic = data.collisionlogic end

    return structure
end

function ECS.createobject(data)
    local object = setmetatable({}, Entity)

    object.x = data.x or 0
    object.y = data.y or 0
    object.alive = data.alive ~= nil and data.alive or true
    object.lifetime = data.lifetime or nil -- nil means infinite lifetime
    object.maxspeed = data.maxspeed or 100

    object.velocityx = 0
    object.velocityy = 0
    object.facing = data.facing or 1
    object.animdata = data.animdata or {
        previousframe = 1,
        lastAnimationPosition = 0
    }

    object.gravity = data.gravity or 0
    object.appliedDragval = data.appliedDragval or 0
    if data.acceleration then
        object.acceleration = data.acceleration
    end

    if data.collisionfilter ~= nil then
        object.collisionfilter = data.collisionfilter
    else
        object.collisionfilter = "slide"
    end
    if data.collision ~= nil then
        object.collision = data.collision
    else
        object.collision = true
    end

    if data.anchored ~= nil then
        object.anchored = data.anchored
    else
        object.anchored = false
    end

    if data.drawdata ~= nil then
        object.drawdata = data.drawdata
    else
        object.drawdata = {
        spritewidth = 94,
        spriteheight = 94,
        r = 0,
        sx = object.facing,
        sy = 1,
        ox = 94/2,
        oy = 0,
        layer = "world"
        }
    end

    if data.name then
        object.name = registername(ECS.entities, data.name)
    end

    if data.grounded ~= nil then -- this is quite unneccessary to even fill
        object.grounded = data.grounded
    else
        object.grounded = false
    end

    if data.imagesprite then
        object.image = {
            image = assetssystem.images[string.lower(data.imagesprite)],
            type = "image"
        }
    end
    object.collider = {
        offsetx = data.collider and data.collider.offsetx or 0,
        offsety = data.collider and data.collider.offsety or 0,
        width = data.collider and data.collider.width or 32,
        height = data.collider and data.collider.height or 32
    }
    if data.beforeupdanim then
        object.beforeupdanim = data.beforeupdanim
    end

    if data.spritepack then
        object.animations = assetssystem.loadpack(data.spritepack, "anim8anim")
    end
    if data.state then -- animation states, e.g "idle", "running" etc
        object.state = data.state
    end
    if data.collisionlogic ~= nil then object.collisionlogic = data.collisionlogic end
    object.behavior = data.behavior or nil
    object.controller = data.controller or nil
    object.type = "object"

    return object
end

function ECS.createparticle(data)
    local particle = setmetatable({}, Entity)

    particle.x = data.x or 0
    particle.y = data.y or 0
    particle.alive = data.alive ~= nil and data.alive or true
    particle.lifetime = data.lifetime or nil

    particle.width = data.width or 32
    particle.height = data.height or 32

    particle.velocityx = data.velocityx or 0
    particle.velocityy = data.velocityy or 0
    particle.facing = data.facing or 1
    particle.animdata = data.animdata or {
        previousframe = 1,
        lastAnimationPosition = 0
    }

    if data.name then
        particle.name = registername(ECS.entities, data.name)
    end

    if data.drawdata ~= nil then
        particle.drawdata = data.drawdata
    else
        particle.drawdata = {
        spritewidth = 94,
        spriteheight = 94,
        r = 0,
        sx = particle.facing,
        sy = 1,
        ox = 94/2,
        oy = 0,
        layer = "world"
        }
    end

    if data.imagesprite then
        particle.image = {
            image = assetssystem.images[data.imagesprite],
            type = "image"
        }
    end

    if data.spritepack then
        particle.animations = assetssystem.loadpack(data.spritepack, "anim8anim")
    end
    particle.state = data.state or "idle"
    if data.beforeupdanim then
        particle.beforeupdanim = data.beforeupdanim
    end
    particle.type = "particle"

    return particle
end

function ECS.createnpc(data)
    local npc = setmetatable({}, Entity)

    npc.x = data.x or 0
    npc.y = data.y or 0
    npc.alive = data.alive ~= nil and data.alive or true

    npc.velocityx = 0
    npc.velocityy = 0
    npc.maxhealth = data.maxhealth or 100
    npc.health = data.health or npc.maxhealth

    npc.acceleration = data.acceleration or 1000
    npc.maxspeed = data.maxspeed or 500
    npc.appliedDragval = data.appliedDragval or 400
    if data.collisionlogic ~= nil then npc.collisionlogic = data.collisionlogic end

    npc.gravity = data.gravity or 400
    npc.jumpforce = data.jumpforce or 500
    if data.collisionfilter ~= nil then
        npc.collisionfilter = data.collisionfilter
    else
        npc.collisionfilter = "cross"
    end
     if data.collision ~= nil then
         npc.collision = data.collision
    else
        npc.collision = true
    end

    if data.spritepack then
        npc.animations = assetssystem.loadpack(data.spritepack, "anim8anim")
    elseif data.imagesprite then
        npc.image = {
            image = assetssystem.images[string.lower(data.imagesprite)],
            type = "image"
        }
    else
        npc.animations = assetssystem.loadpack("stickman", "anim8anim")
    end
    npc.facing = data.facing or 1
    npc.animdata = data.animdata or {
        previousframe = 1,
        lastAnimationPosition = 0
    }
    npc.state = "idle"
    npc.anchored = data.anchored or false
    npc.grounded = data.grounded or false

    if data.name then
        npc.name = registername(ECS.entities, data.name)
    end

    if data.controller ~= nil then
        npc.controller = data.controller
    else
        npc.controller = function(entity, dt)
            if entity.velocityx ~= 0 and entity.appliedDragval ~= 0 then
                physics.drag(entity, dt)
            end
            if entity.gravity ~= 0 then
                physics.gravity(entity, dt)
            end

            if entity.velocityx > entity.maxspeed or entity.velocityx < -entity.maxspeed then
                entity.velocityx = physics.clamp(entity.velocityx, -entity.maxspeed, entity.maxspeed)
            end
        end
    end
    npc.lifetime = data.lifetime or nil

    if data.beforedying ~= nil then
        npc.beforedying = data.beforedying 
    end
    npc.behavior = data.behavior or function() end

    if data.drawdata ~= nil then
        npc.drawdata = data.drawdata
    else
        npc.drawdata = {
        spritewidth = 94,
        spriteheight = 94,
        r = 0,
        sx = npc.facing,
        sy = 1,
        ox = 94/2,
        oy = 0,
        drawlayer = "world"
        }
    end
    if data.beforeupdanim then
        npc.beforeupdanim = data.beforeupdanim
    else
        npc.beforeupdanim = function(entity, dt)
            if entity.state == "running" and entity.animations.running and entity.maxspeed > 0 then
                local runAnimation = entity.animations.running.animation
                local velocityPercentage = math.min(math.abs(entity.velocityx) / entity.maxspeed, 1)
                local frameDuration = 0.12 - (0.12 - 0.06) * velocityPercentage
                local elapsed = 0

                for index = 1, #runAnimation.durations do
                    runAnimation.durations[index] = frameDuration
                    elapsed = elapsed + frameDuration
                    runAnimation.intervals[index + 1] = elapsed
                end

                runAnimation.totalDuration = elapsed
            end
        end
    end

    npc.collider = {
        offsetx = data.collider and data.collider.offsetx or 24,
        offsety = data.collider and data.collider.offsety or 0,
        width = data.collider and data.collider.width or 47,
        height = data.collider and data.collider.height or 94
    }
    npc.type = "npc"

    return npc
end

function ECS.createplayer(data)
    local self = setmetatable({}, Entity)

    self.x = data.x or 0
    self.y = data.y or 0
    self.alive = data.alive ~= nil and data.alive or true

    self.velocityx = 0
    self.velocityy = 0
    self.maxhealth = data.maxhealth or 100
    self.health = data.health or self.maxhealth

    self.acceleration = data.acceleration or 1000
    self.maxspeed = data.maxspeed or 500
    self.appliedDragval = data.appliedDragval or 700
    self.originalAppliedDragval = self.appliedDragval

    self.gravity = data.gravity or 400
    self.jumpforce = data.jumpforce or 500
    if data.collisionfilter ~= nil then
        self.collisionfilter = data.collisionfilter
    else
        self.collisionfilter = "cross"
    end
     if data.collision ~= nil then
         self.collision = data.collision
    else
        self.collision = true
    end
    if data.spritepack then
        self.animations = assetssystem.loadpack(data.spritepack, "anim8anim")
    elseif data.imagesprite then
        self.image = {
            image = assetssystem.images[string.lower(data.imagesprite)],
            type = "image"
        }
    else
        self.animations = assetssystem.loadpack("stickman", "anim8anim")
    end

    self.facing = data.facing or 1
    self.animdata = data.animdata or {
        previousframe = 1,
        lastAnimationPosition = 0
    }
    self.state = "idle"
    self.anchored = data.anchored or false
    self.grounded = data.grounded or false
    self.hardslide = data.hardslide or false
    if data.name then
        self.name = registername(ECS.entities, data.name)
    end
    self.input = data.input or {
        blockinput = false,
        left = "a",
        right = "d",
        jump = "space"
    }
    self.customkeys = data.customkeys or {}
    self.customkeys.m1Timer = 0
    self.controller = data.controller or function(entity, dt)
        if entity.hardslide == true and entity.appliedDragval == entity.originalAppliedDragval then
            entity.appliedDragval = entity.appliedDragval * 3
        elseif entity.hardslide == false and entity.appliedDragval ~= entity.originalAppliedDragval then
            entity.appliedDragval = entity.originalAppliedDragval
        end
        if love.keyboard.isDown(entity.input.right) and not entity.input.blockinput then
            entity.velocityx = entity.velocityx + entity.acceleration * dt
            entity.facing = 1
        elseif love.keyboard.isDown(entity.input.left) and not entity.input.blockinput then
            entity.velocityx = entity.velocityx - entity.acceleration * dt
            entity.facing = -1
        end
        if entity.velocityx ~= 0 and not (love.keyboard.isDown(entity.input.left) and love.keyboard.isDown(entity.input.right)) then
            physics.drag(entity, dt)
        end
        entity.velocityx = physics.clamp(entity.velocityx, -entity.maxspeed, entity.maxspeed)
        if entity.gravity ~= 0 then
             physics.gravity(entity, dt)
        end
    end

    if data.beforedying ~= nil then
        self.beforedying = data.beforedying 
    end
    if data.behavior ~= nil then
        self.behavior = data.behavior
    else
        self.behavior = function(entity, dt)
            if entity.state ~= "m1" then
                if not entity.grounded then
                    entity:setState("jumping")
                elseif love.keyboard.isDown(entity.input.left) or love.keyboard.isDown(entity.input.right) then
                    entity:setState("running")
                elseif math.abs(entity.velocityx) > 5 then
                    entity:setState("sliding")
                else
                    entity:setState("idle")
                end
            elseif entity.state == "m1" then
                entity.customkeys.m1Timer = entity.customkeys.m1Timer + dt
                local animDuration = entity.animations.m1.animation.totalDuration or 10.9
                if entity.customkeys.m1Timer >= animDuration then
                    entity:setState("idle")
                    entity.hardslide = false
                    entity.appliedDragval = entity.originalAppliedDragval
                    entity.customkeys.m1Timer = 0
                end
            end
        end
    end
    if data.mousepressfunction then
        self.mousepressfunction = data.mousepressfunction
    else
        self.mousepressfunction = function(x, y, button, entity)
            if button == 1 then
                entity:setState("m1")
                entity.hardslide = true
                entity.customkeys.m1Timer = 0
            end
        end
    end
    if data.keyreleasefunction then
        self.keyreleasefunction = data.keyreleasefunction
    else
        self.keyreleasefunction = function(key, entity)
    end
    end
    if data.keypressfunction then
        self.keypressfunction = data.keypressfunction
    else
        self.keypressfunction = function(key, entity)
            if key == "space" and entity.grounded then
                entity.velocityy = -entity.jumpforce
            end
        end
    end

    if data.drawdata ~= nil then
        self.drawdata = data.drawdata
    else
        self.drawdata = {
            spritewidth = 94,
            spriteheight = 94,
            r = 0,
            sx = self.facing,
            sy = 1,
            ox = 94 / 2,
            oy = 0,
            layer = "world"
        }
    end
    if data.collisionlogic ~= nil then self.collisionlogic = data.collisionlogic end
    if data.beforeupdanim then
        self.beforeupdanim = data.beforeupdanim
    else
        self.beforeupdanim = function(entity, dt)
            if entity.state == "running" and entity.animations.running and entity.maxspeed > 0 then
                local runAnimation = entity.animations.running.animation
                local velocityPercentage = math.min(math.abs(entity.velocityx) / entity.maxspeed, 1)
                local frameDuration = 0.12 - (0.12 - 0.06) * velocityPercentage
                local elapsed = 0

                for index = 1, #runAnimation.durations do
                    runAnimation.durations[index] = frameDuration
                    elapsed = elapsed + frameDuration
                    runAnimation.intervals[index + 1] = elapsed
                end

                runAnimation.totalDuration = elapsed
            end
        end
    end
    self.collider = {
        offsetx = data.collider and data.collider.offsetx or 24,
        offsety = data.collider and data.collider.offsety or 0,
        width = data.collider and data.collider.width or 47,
        height = data.collider and data.collider.height or 94
    }
    self.type = "player"

    return self
end

function ECS.keypressfunction(key, entity)
    if entity.keypressfunction then
        entity.keypressfunction(key, entity)
    end
end

function ECS.mousepressfunction(x, y, button, entity)
    if entity.mousepressfunction then
        entity.mousepressfunction(x, y, button, entity)
    end
end

function ECS.keyreleasefunction(key, entity)
    if entity.keyreleasefunction then
        entity.keyreleasefunction(key, entity)
    end
end

function ECS.update(dt, entity)
    -- Update animations
    if entity.animations and entity.state then
        local anim = entity.animations[entity.state]
        if anim then
            if entity.beforeupdanim then
                entity.beforeupdanim(entity, dt)
            end
            local animObj = anim.animation or anim
            if animObj and animObj.update then
                entity.animdata.previousframe = animObj.position
                animObj:update(dt)
            end
        end
    end

    if entity.type == "object" and entity.alive then -- object updating
        if not entity.anchored then
            if entity.controller then
                entity.controller(entity, dt)
            end
            if entity.velocityx ~= 0 and entity.appliedDragval ~= 0 then
                physics.drag(entity, dt)
            end
            if entity.gravity ~= 0 then
                physics.gravity(entity, dt)
            end
        else
            entity.velocityx = 0
            entity.velocityy = 0
        end
        
        if entity.lifetime ~= nil then
            if entity.lifetime > 0 then
                entity.lifetime = entity.lifetime - dt
            end
            if entity.lifetime <= 0 then
                entity.alive = false
            end
        end
        
        if entity.state ~= nil then
            entity.behavior(entity, dt) -- for special behavior purposes, must be a function
        end

    elseif entity.type == "particle" and entity.alive then 
        entity.x = entity.x + entity.velocityx * dt
        entity.y = entity.y + entity.velocityy * dt
        
        if entity.lifetime ~= nil then
            if entity.lifetime > 0 then
                entity.lifetime = entity.lifetime - dt
            end
            if entity.lifetime <= 0 then
                entity.alive = false
            end
        end

    elseif entity.type == "npc" and entity.alive then
        if not entity.anchored then
            entity.controller(entity, dt)
        else
            entity.velocityx = 0
            entity.velocityy = 0
        end

        entity.behavior(entity, dt)

        if entity.health <= 0 then
            if entity.beforedying ~= nil then
                entity.beforedying(entity, dt) -- Optional death callback/animation
            else
                entity.alive = false
            end
        end

    elseif entity.type == "player" and entity.alive then 
        if not entity.anchored then
            entity.controller(entity, dt)
        else
            entity.velocityx = 0
            entity.velocityy = 0
        end
        
        entity.behavior(entity, dt)

        if entity.health <= 0 then
            if entity.beforedying ~= nil then
                entity.beforedying(entity, dt) -- Optional death callback/animation
            else
                entity.alive = false
            end
        end
    end
end

return ECS