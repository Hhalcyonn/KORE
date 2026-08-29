local timer = require("libs/hump/timer")
local camera = require("libs/hump/camera")
local suit = require("libs/suit")
local ECS = require("src/EntityComponentSystem")
local AssetsSystem = require("src/AssetsSystem")
local WorldSystem = require("src/WorldComponentSystem")
local RenderSystem = require("src/RenderComponentSystem")
local utils = require("src/utils")
local ConsoleSystem = require("src/Console")
local Prefabs = require("src/Prefabs")
local phsyics = require("src/PhysicsComponentSystem")

local entities = {}
ECS.setentities(entities)
local player
local smiler
local cam
local debug = false
local function removeDeadEntities()
    for index = #entities, 1, -1 do
        local entity = entities[index]

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

function love.load()
    math.randomseed(os.time())
    AssetsSystem.loadimages()
    cam = camera()
    WorldSystem.loadworld()

    player = ECS.createplayer({
        x = -50000,
        y = 0,
        spritepack = "stickman",
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

    ECS.addentity(player)
    table.insert(entities, ECS.createstructure({
        x = -50000,
        y = 500,
        width = 100000,
        height = 50
    }))
    table.insert(entities, ECS.createstructure({
        x = 0,
        y = 0,
        width = 50,
        height = 400
    }))
    cam:zoomTo(0.5)

    WorldSystem.addtoworld(entities)

    ConsoleSystem:init({
        entities = entities,
        player = player,
        WorldSystem = WorldSystem,
        setDebug = function(value)
            debug = value
        end
    })
end

function love.keypressed(key)
    if ConsoleSystem:keypressed(key) then
        return
    end

    ECS.keypressfunction(key, player, 0)
    if key == "escape" then
        love.event.quit()
    end

    if key == "p" then
        debug = not debug
    end
end

function love.update(dt)
    phsyics.initializedt(dt)
    ECS.initializedt(dt)
    for _, entity in ipairs(entities) do
        ECS.update(dt, entity)
    end
    ConsoleSystem:update()
    WorldSystem.update(entities, dt)
    removeDeadEntities()
    timer.update(dt)
    cam:lookAt(player.x + player.drawdata.spritewidth / 2, player.y + player.drawdata.spriteheight / 2)
end

function love.draw()
    cam:attach()
    love.graphics.setColor(1, 1, 1)
    RenderSystem:draw(entities)
    if debug then
        love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle(
                "line",
                player.x + player.collider.offsetx,
                player.y + player.collider.offsety,
                player.collider.width,
                player.collider.height
            )
    end
    love.graphics.setColor(1, 1, 1)
    cam:detach()
    ConsoleSystem:draw()
    if debug then
        love.graphics.print("Player VelocityX: " .. math.floor(player.velocityx), 0, 280)
        love.graphics.print("Player VelocityY: " .. math.floor(player.velocityy), 0, 300)
        love.graphics.print("Player State: " .. player.state, 0, 320)
        love.graphics.print("Player Facing: " .. player.facing, 0, 340)
        if player.grounded then
        love.graphics.print("Player Grounded: true", 0, 360)
        else
        love.graphics.print("Player Grounded: false", 0, 360)
        end
        local count = 0
        for _, entity in pairs(entities) do
            count = count + 1
        end
        love.graphics.print("Entity count: " .. count, 0, 380)
    end
end

function love.textinput(text)
    ConsoleSystem:textinput(text)
end

function love.textedited(text, start, length)
    ConsoleSystem:textedited(text, start, length)
end
