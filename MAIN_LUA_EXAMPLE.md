# How Your main.lua File Should Look Like With the Framework

This document shows how to structure your `main.lua` file when using L2D-BootlegSet as a framework in your own game.

## Basic Setup

```lua
-- main.lua - Your game's entry point

-- Import the framework
local Framework = require("init")

-- Destructure commonly used modules for convenience
local ECS = Framework.ECS
local AssetsSystem = Framework.AssetsSystem
local WorldSystem = Framework.WorldSystem
local RenderSystem = Framework.RenderSystem
local ConsoleSystem = Framework.Console
local Prefabs = Framework.Prefabs
local Utils = Framework.Utils
local Physics = Framework.Physics

-- Also require HUMP dependencies (included in the framework)
local timer = require("libs/hump/timer")
local camera = require("libs/hump/camera")

-- Game state variables
local player
local cam
local debug = false

-- Cleanup function for dead entities
local function removeDeadEntities()
    for index = #ECS.entities, 1, -1 do
        local entity = ECS.entities[index]
        
        if not entity.alive then
            WorldSystem.removefromworld(entity)
            ECS.removeentity(entity)
            
            -- Cleanup entity-specific data
            entity.controller = nil
            entity.behavior = nil
            entity.animations = nil
        end
    end
end

-- LÖVE Callbacks
function love.load()
    math.randomseed(os.time())
    
    -- Initialize systems
    AssetsSystem.loadimages()
    cam = camera()
    WorldSystem.initworld(64)
    
    -- Create your player using Prefabs or ECS
    player = Prefabs.createCharacter("white", 0, 0, "player")
    ECS.register(player)
    
    -- Load other entities (e.g., from a map)
    local mapStructures = AssetsSystem.loadpack("maporigin", "map")
    for _, structure in ipairs(mapStructures or {}) do
        ECS.register(structure)
    end
    
    -- Setup camera
    cam:zoomTo(0.5)
    
    -- Add all entities to the physics world
    WorldSystem.addtoworld(ECS.entities)
    
    -- Initialize the debug console
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
    -- Convert screen coordinates to world coordinates
    local worldX, worldY = cam:worldCoords(x, y)
    
    -- Send mouse press to all entities
    for _, entity in ipairs(ECS.entities) do
        ECS.mousepressfunction(worldX, worldY, button, entity, 0)
    end
end

function love.keypressed(key)
    -- Handle console input first
    if ConsoleSystem:keypressed(key) then
        return
    end
    
    -- Send key press to all entities
    for _, entity in ipairs(ECS.entities) do
        ECS.keypressfunction(key, entity, 0)
    end
    
    -- Allow escape to quit
    if key == "escape" then
        love.event.quit()
    end
end

function love.update(dt)
    -- Initialize delta time for systems
    Physics.initializedt(dt)
    ECS.initializedt(dt)
    
    -- Update all entities
    for _, entity in ipairs(ECS.entities) do
        ECS.update(dt, entity)
    end
    
    -- Update console
    ConsoleSystem:update()
    
    -- Update physics and collisions
    WorldSystem.update(ECS.entities, dt)
    
    -- Clean up dead entities
    removeDeadEntities()
    
    -- Update timers
    timer.update(dt)
    
    -- Update camera to follow player
    cam:lookAt(player.x + player.drawdata.spritewidth / 2, player.y + player.drawdata.spriteheight / 2)
end

function love.draw()
    -- Attach camera for world rendering
    cam:attach()
    love.graphics.setColor(1, 1, 1)
    
    -- Draw all entities
    RenderSystem:draw(ECS.entities)
    
    -- Draw debug visuals if enabled
    if debug then
        RenderSystem:drawdebuginworld(ECS.entities)
    end
    
    love.graphics.setColor(1, 1, 1)
    cam:detach()
    
    -- Draw UI (console, HUD, etc) - not affected by camera
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
