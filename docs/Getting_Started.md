# Getting Started

KORE is a lightweight, developer-controlled 2D framework for LÖVE2D.

This guide will get a basic KORE project running.

## 1. Add KORE to your project

Copy the `KORE/` directory into your LÖVE2D project.

A basic project can look like this:

```text
MyGame/
├── main.lua
├── KORE/
└── assets/
    ├── sprites/
    ├── spritepacks/
    ├── sounds/
    ├── fonts/
    └── shaders/
```

The default asset paths are:

```text
assets/sprites
assets/spritepacks
assets/world
assets/sounds
assets/fonts
assets/shaders
```

You can change these paths with `KORE.initAssetsPath()` if your project uses a different structure.

## 2. Require KORE

In `main.lua`:

```lua
local KORE = require("KORE")
```

## 3. Initialize KORE

Use `love.load()` to configure and load KORE:

```lua
function love.load()

    KORE.initAssetsPath()

    KORE.load()

end
```

`KORE.initAssetsPath()` is optional if you are using the default asset folders.

## 4. Create an entity

Entities are created by passing a data table to `KORE.spawnEntity()`.

```lua
function love.load()

    KORE.initAssetsPath()
    KORE.load()

    local player = KORE.spawnEntity({
        name = "player",
        x = 100,
        y = 100
    })

end
```

KORE automatically gives the entity an identity containing a unique ID, a unique name, and tags.

You can also store your own data on an entity:

```lua
local player = KORE.spawnEntity({
    name = "player",

    x = 100,
    y = 100,

    tags = {
        player = true
    },

    customkeys = {
        coins = 0,
        canDash = true
    }
})
```

KORE does not require your game to follow a specific architecture. Your entities can contain whatever additional data your game needs.

## 5. Connect the game loop

KORE provides its own update and draw functions.

```lua
function love.update(dt)
    KORE.update(dt)
end

function love.draw()
    KORE.draw()
end
```

For input, forward the relevant LÖVE callbacks to KORE:

```lua
function love.keypressed(key)
    KORE.keypressed(key)
end

function love.keyreleased(key)
    KORE.keyreleased(key)
end

function love.mousepressed(x, y, button)
    KORE.mousepressed(x, y, button)
end

function love.textinput(text)
    KORE.textinput(text)
end
```

## 6. Complete minimal example

Your `main.lua` can now be:

```lua
local KORE = require("KORE")

function love.load()

    KORE.initAssetsPath()
    KORE.load()

    KORE.spawnEntity({
        name = "player",
        x = 100,
        y = 100
    })

end

function love.update(dt)
    KORE.update(dt)
end

function love.draw()
    KORE.draw()
end

function love.keypressed(key)
    KORE.keypressed(key)
end

function love.keyreleased(key)
    KORE.keyreleased(key)
end

function love.mousepressed(x, y, button)
    KORE.mousepressed(x, y, button)
end

function love.textinput(text)
    KORE.textinput(text)
end
```

Run the project with LÖVE2D.

## Where to go next

Once the basic project is working, see the other documentation for:

* **Entity Component System** — creating entities, identity, tags, health, events, and entity lifecycle.
* **Entity Methods** — built-in methods available on entities.
* **AssetsSystem** — images, sounds, fonts, shaders, sprite packs, and world packs.
* **PhysicsSystem** — physics bodies, movement, forces, gravity, drag, and friction.
* **WorldSystem** — collision and world management.
* **RenderSystem** — sprites, animations, layers, shaders, and rendering.
* **Console & Commands** — KORE's development console.
* **Logging** — runtime logging and debugging.

KORE is designed to provide runtime tools without dictating how you structure your game.