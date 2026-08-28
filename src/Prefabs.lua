local prefabs = {}
local ECS = require("src/EntityComponentSystem")
local utils = require("src/utils")
prefabs.__index = prefabs

function prefabs.createSmiler(posx, posy, target)
    return ECS.createobject({
    x = posx,
    y = posy,
    imagesprite = "smiler.png",
    name = "smiler",
    maxspeed = 2000,
    gravity = 0,
    width = 420,
    collision = false,
    acceleration = 3000,
    height = 420,
    dragval = 100,
    anchored = false,
    drawdata = {
        spritewidth = 420,
        spriteheight = 420,
        r = 0,  
        sx = 1,
        sy = 1,
        ox = 100,
        oy = 0
    },
    controller = function(entity, dt)
        if not target then
            return
        end

        local dist = utils.distance(entity, target)
        if dist > 1 then
            entity:moveTo(target)
        end
    end
    })
end

function prefabs.createCharacter(character, posx, posy, chartype)
    if chartype == "player" then
        if character == "white" then
            return ECS.createplayer({
            x = posx,
            y = posy,
            spritepack = "stickman",
            name = "white",
            dragval = 500,
            maxspeed = 1000,
            controller = function(entity, dt)
                local physics = require("src/PhysicsComponentSystem")
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
            end,
            behavior = function(entity, dt)
                if not entity.grounded then
                    entity.state = "jumping"
                elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
                    entity.state = "running"
                elseif math.abs(entity.velocityx) > 5 then
                    entity.state = "sliding"
                else
                    entity.state = "idle"
                end
            end
            })
        end
    elseif chartype == "npc" then
        if character == "white" then
            return ECS.createnpc({
            x = posx,
            y = posy,
            name = "white",
            spritepack = "stickman",
            dragval = 500,
            maxspeed = 1000,
            behavior = function(entity, dt)
                if not entity.grounded then
                    entity.state = "jumping"
                elseif entity.velocityx ~= 0 then
                    entity.state = "running"
                elseif math.abs(entity.velocityx) > 5 then
                    entity.state = "sliding"
                else
                    entity.state = "idle"
                end
            end
            })
        end
    end
end

return prefabs