# How Your main.lua File Should Look Like With the Framework

This document shows how to structure your `main.lua` file when using L2D-BootlegSet as a framework in your own game.

## How your main.lua should look like at first with  this framework

```lua

local Framework = require("init")
local ECS = Framework.ECS
local AssetsSystem = Framework.AssetsSystem
local WorldSystem = Framework.WorldSystem
local RenderSystem = Framework.RenderSystem
local ConsoleSystem = Framework.Console
local Prefabs = Framework.Prefabs
local Utils = Framework.Utils
local Physics = Framework.Physics
local camera = require("libs/hump/camera") -- or "L2D-BootlegSet/libs/hump/camera" if you dont have libs folder on your game.
local cam
local debug = false

function love.load()
    math.randomseed(os.time())
    AssetsSystem.loadimages()
    cam = camera()
    WorldSystem.initworld()
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
end

function love.update(dt)
    Physics.initializedt(dt)
    ECS.initializedt(dt)
    for _, entity in ipairs(ECS.entities) do
        ECS.update(dt, entity)
    end
    ConsoleSystem:update()
    WorldSystem.update(ECS.entities, dt)
    ECS.removeDeadEntities()
    cam:lookAt(0, 500)
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
```

## Key Points

1. **Import the Framework**: Use `require("init")` to load all framework modules at once.

2. **Destructure Modules**: Extract the modules you need from the Framework table for cleaner code.

3. **Follow the Update Loop**: The order in `love.update()` matters:
   - Initialize delta time
   - Update entities
   - Update console
   - Update physics/collisions
   - Clean up dead entities
   - Update timers
   - Update camera

4. **Use the ECS**: Register all entities with `ECS.register()` and let the framework handle them.

5. **Camera Management**: Use the included HUMP camera to smoothly follow the player.

6. **Console System**: Initialize it with entity references for debugging commands.

## Customization

You can:
- Create your own entity types using `ECS.createplayer()`, `ECS.createnpc()`, etc.
- Add custom behaviors and controllers to entities
- Override rendering logic in `RenderSystem`
- Add your own systems and management logic

## Running Your Game

Simply run:
```bash
love .
```

The framework will automatically require your `main.lua` and handle all the game loop callbacks.
