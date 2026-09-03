# KORE `main.lua` Example

This document shows the basic LÖVE 2D callbacks for using KORE as a framework.

## Example

```lua

local KORE = require("KORE")
local camera

function love.load()
    camera = KORE.setCamera()
    KORE.initAssetsPath({
        spritefolder = "assets/sprites",
        spritepacksfolder = "assets/spritepacks",
        worldpackfolder = "assets/WorldPack",
        soundfolder = "assets/sounds",
        fontfolder = "assets/fonts"
    })
    KORE.load()
end

function love.keypressed(key)
    KORE.keypressed(key)
end

function love.keyreleased(key)
    KORE.keyreleased(key)
end

function love.update(dt)
    KORE.update(dt)
    camera:lookAt(0, 0)
end

function love.draw()
    KORE.draw()
end

function love.textinput(text)
    KORE.textinput(text)
end

function love.textedited(text, start, length)
    KORE.textedited(text, start, length)
end
```

## Key Points

1. **Import the Framework**: Use `require("KORE")` when `KORE.lua` is at the project root.

2. **Initialize Assets**: Call `KORE.initAssetsPath()` before `KORE.load()`.

3. **Follow the Update Loop**: Pass LÖVE's `dt` to `KORE.update(dt)`.

4. **Use the ECS**: Register all entities with `ECS.register()` and let the framework handle them.

5. **Camera Management**: `KORE.setCamera()` returns the HUMP camera instance.

6. **Input**: Forward the LÖVE input and text callbacks to KORE as needed.

## Customization

You can:

- Create entities with `ECS.createplayer()`, `ECS.createnpc()`, and the other ECS constructors.
- Add custom behaviors and controllers to entities.
- Override rendering logic in `RenderSystem`.
- Add your own systems and entity management logic.

## Entity Methods

Entities created by the ECS provide these methods:

```lua
entity:moveTo(target, speed, dt)
entity:faceTo(target)
entity:setState("running")
entity:enteredFrame(1)
entity:Destroy()
entity:distance(target)
```

## Running Your Game

Simply run:
```bash
love .
```

The framework will automatically require your `main.lua` and handle all the game loop callbacks.
