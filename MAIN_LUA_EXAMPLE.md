# How Your main.lua File Should Look Like With the Framework

This document shows how to structure your `main.lua` file when using L2D-BootlegSet as a framework in your own game.

## How your main.lua should look like at first with  this framework

```lua

local KORE = require("KORE/KORE")
local humpcamera = require("KORE/libs/hump/camera") -- ONLY IF YOU WANT CAMERA
local camera -- ONLY IF YOU WANT CAMERA

function love.load()
    camera = humpcamera() -- ONLY IF CAMERA EXIST
    KORE.setCamera() -- ONLY IF CAMERA EXIST
    KORE.initAssetsPath({
        spritefolder = yourspritefolderpath
        spritepacksfolder = yourspritepacksfolderpath
        worldpackfolder = yourworldpackfolderpath
        soundfolder = yoursoundfolderpath
        fontfolder = yourfontfolderpath
    })
    KORE.load()
end

function love.mousepressed(x, y, button)
    if camera then
        local worldX, worldY = cam:worldCoords(x, y)
        KORE.mousepressed(worldX, worldY, button)
    else
        KORE.mousepressed(x, y, button)
    end
end

function love.keypressed(key)
    KORE.keypressed(key)
end

function love.update(dt)
    KORE.update(dt)
    camera:lookAt(0, 0) -- ONLY IF CAMERA EXIST
end

function love.draw()
    camera:attach() -- ONLY IF CAMERA EXIST
    KORE.drawinworld()
    camera:detach() -- ONLY IF CAMERA EXIST
    KORE.drawonscreen()
end

function love.textinput(text)
    KORE.textinput(text)
end

function love.textedited(text, start, length)
    KORE.textedited(text, start, length)
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
