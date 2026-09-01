

local ECS = {}
local assetssystem = require("src/AssetsSystem")
local physics = require("src/PhysicsComponentSystem")
local utils = require("src/utils")
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
local deltatime
function ECS.initializedt(dt)
    deltatime = dt
end

function ECS.setentities(entitylist)
    ECS.entities = entitylist
end

function ECS.register(entity)
    table.insert(ECS.entities, entity)
    if entity.type then
        table.insert(ECS.typebatch[entity.type .. "s"], entity)
    end
    if entity.name then
        local name, num = utils.splitname(entity.name)
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
                local name, num = utils.splitname(entity.name)
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

local Entity = {}
Entity.__index = Entity
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
        oy = 0
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
    object.previousframe = 1

    object.gravity = data.gravity or 0
    object.dragval = data.dragval or 0
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
        oy = 0
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

function ECS.createParticle(data)
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
        oy = 0
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
    npc.dragval = data.dragval or 400
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
    npc.previousframe = 1
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
            if entity.velocityx ~= 0 and entity.dragval ~= 0 then
                physics.drag(entity, dt)
            end
            if entity.gravity ~= 0 then
                physics.gravity(entity, dt)
            end

            if entity.velocityx > entity.maxspeed or entity.velocityx < -entity.maxspeed then
                entity.velocityx = utils.clamp(entity.velocityx, -entity.maxspeed, entity.maxspeed)
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
        oy = 0
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
    self.dragval = data.dragval or 400

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
    self.previousframe = 1
    self.state = "idle"
    self.anchored = data.anchored or false
    self.grounded = data.grounded or false
    if data.name then
        self.name = registername(ECS.entities, data.name)
    end
    self.controller = data.controller or function(entity, dt)
        if love.keyboard.isDown("d") and not entity.anchored then
            entity.velocityx = entity.velocityx + entity.acceleration * dt
            entity.facing = 1
        elseif love.keyboard.isDown("a") and not entity.anchored then
            entity.velocityx = entity.velocityx - entity.acceleration * dt
            entity.facing = -1
        end
        if entity.velocityx ~= 0 and not (love.keyboard.isDown("a") and love.keyboard.isDown("d")) then
            physics.drag(entity, dt)
        end
        if entity.velocityx > entity.maxspeed then
            entity.velocityx = entity.maxspeed
        elseif entity.velocityx < -entity.maxspeed then
            entity.velocityx = -entity.maxspeed
        end
        if entity.gravity ~= 0 then
             physics.gravity(entity, dt)
        end
    end

    if data.beforedying ~= nil then
        self.beforedying = data.beforedying 
    end
    if data.customkeys ~= nil then
        self.customkeys = data.customkeys
    end
    if data.behavior ~= nil then
        self.behavior = data.behavior
    else
        self.behavior = function(entity)
            if not entity.grounded then
                entity:setState("jumping")
            elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
                entity:setState("running")
            elseif math.abs(entity.velocityx) > 5 then
                entity:setState("sliding")
            else
                entity:setState("idle")
            end
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
            oy = 0
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

function Entity:faceTo(target)
    if not target or not target.x or not target.y then
        error(tostring(target) .. "Has no x or y coordinates, err call > :faceTo()")
    end
    if not self.drawdata then
        error(tostring(self) .. "Has no drawdata, err call > :faceTo()")
    end
    if not self.x or not self.y then
        error(tostring(self) .. "Has no x or y coordinates, err call > :faceTo()")
    end
    local dx = target.x - self.x
    local dy = target.y - self.y
    self.drawdata.r = math.atan2(dy, dx)
end

function Entity:moveTo(target, speed)
    speed = speed or self.maxspeed

    local selfCenterX = self.x + self.drawdata.spritewidth / 2
    local selfCenterY = self.y + self.drawdata.spriteheight / 2
    local targetCenterX = target.x + target.drawdata.spritewidth / 2
    local targetCenterY = target.y + target.drawdata.spriteheight / 2
    local dragval = self.dragval
    local acceleration = self.acceleration or nil
    local dx = targetCenterX - selfCenterX
    local dy = targetCenterY - selfCenterY
    local distance = utils.distance(self, target)

    if dx == 0 and dy == 0 and dragval == 0 then
        self.velocityx = 0
        self.velocityy = 0
        return
    elseif dragval ~= 0 then
        physics.drag(self)
    end

    local angle = math.atan2(dy, dx)
    if distance ~= 0 then
        if acceleration then
            local accelerationStep = acceleration * deltatime
            self.velocityx = self.velocityx + math.cos(angle) * accelerationStep
            self.velocityy = self.velocityy + math.sin(angle) * accelerationStep

            local velocity = math.sqrt(self.velocityx * self.velocityx + self.velocityy * self.velocityy)
            if velocity > speed then
                local scale = speed / velocity
                self.velocityx = self.velocityx * scale
                self.velocityy = self.velocityy * scale
            end
        else
            self.velocityx = math.cos(angle) * speed
            self.velocityy = math.sin(angle) * speed
        end
    end
end

function Entity:Destroy(entity)
    self.alive = false
end

function Entity:enteredFrame(frame)
    if self.animations and self.state then
        local anim = self.animations[self.state].animation
        if anim ~= nil then
            return (anim.position == frame) and (self.previousframe ~= frame)
        end
    end
end

function Entity:setState(newState)
    if self.state == newState then
        return
    end

    self.state = newState
    local anim = self.animations[newState]
    if anim and anim.animation then
        anim.animation:gotoFrame(1)
    end
end

function ECS.keypressfunction(key, entity, dt)
    if entity.keypressfunction then
        entity.keypressfunction(key, entity, dt)
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
                entity.previousframe = animObj.position
                animObj:update(dt)
            end
        end
    end

    if entity.type == "object" and entity.alive then -- object updating
        if not entity.anchored then
            if entity.controller then
                entity.controller(entity, dt)
            end
            if entity.velocityx ~= 0 and entity.dragval ~= 0 then
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