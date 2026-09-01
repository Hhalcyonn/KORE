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
    collision = false,
    acceleration = 3000,
    appliedDragval = 100,
    anchored = false,
    drawdata = {
        spritewidth = 768,
        spriteheight = 768,
        r = 0,  
        sx = 1,
        sy = 1,
        ox = 100,
        oy = 0
    },
    collider = {
        width = 768,
        height = 768
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
            name = "stickmanwhite",
            appliedDragval = 500,
            maxspeed = 1000
            })
        end
    elseif chartype == "npc" then
        if character == "white" then
            return ECS.createnpc({
            x = posx,
            y = posy,
            name = "stickmanwhite",
            spritepack = "stickman",
            appliedDragval = 500,
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