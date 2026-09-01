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
local physics = require("src/PhysicsComponentSystem")

local player
local smiler
local cam
local debug = false
local function removeDeadEntities()
    for index = #ECS.entities, 1, -1 do
        local entity = ECS.entities[index]

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
    WorldSystem.initworld(64)

    player = Prefabs.createCharacter("white", -5000, 0, "player")

    ECS.register(player)

    local mapStructures = AssetsSystem.loadpack("maporigin", "map")
    for _, structure in ipairs(mapStructures or {}) do
        ECS.register(structure)
    end

    cam:zoomTo(0.5)

    WorldSystem.addtoworld(ECS.entities)

    ConsoleSystem:init({
        entities = ECS.entities,
        subtypebatch = ECS.subtypebatch,
        typebatch = ECS.typebatch,
        player = player,
        WorldSystem = WorldSystem,
        setDebug = function(value)
            debug = value
        end
    })
end

function love.mousepressed(x, y, button)
    local worldX, worldY = cam:worldCoords(x, y)
    for _, entity in ipairs(ECS.entities) do
        ECS.mousepressfunction(worldX, worldY, button, entity, 0)
    end
end

function love.keypressed(key)
    if ConsoleSystem:keypressed(key) then
        return
    end
    for _, entity in ipairs(ECS.entities) do
        ECS.keypressfunction(key, entity, 0)
    end
    if key == "escape" then
        love.event.quit()
    end
end

function love.update(dt)
    physics.initializedt(dt)
    ECS.initializedt(dt)
    for _, entity in ipairs(ECS.entities) do
        ECS.update(dt, entity)
    end
    ConsoleSystem:update()
    WorldSystem.update(ECS.entities, dt)
    removeDeadEntities()
    timer.update(dt)
    cam:lookAt(player.x + player.drawdata.spritewidth / 2, player.y + player.drawdata.spriteheight / 2)
end

function love.draw()
    cam:attach()
    love.graphics.setColor(1, 1, 1)
    RenderSystem:draw(ECS.entities)
    if debug then
        RenderSystem:drawdebuginworld(ECS.entities)
    end
    love.graphics.setColor(1, 1, 1)
    cam:detach()
    ConsoleSystem:draw()
    if debug then
        RenderSystem:drawdebugonscreen(ECS.entities)
    end
end

function love.textinput(text)
    ConsoleSystem:textinput(text)
end

function love.textedited(text, start, length)
    ConsoleSystem:textedited(text, start, length)
end
