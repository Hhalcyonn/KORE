# KORE

### Kreator Oriented Runtime Engine

A lightweight, developer-controlled **2D game framework for LÖVE2D**.

KORE provides the runtime systems you need to build a game while keeping your game's architecture in your hands.

**No editor. No mandatory architecture. No unnecessary abstraction.**

---

## Features

* **Entity Component System** — flexible Lua-based entities
* **Rendering** — sprites, animations, layers, and debug rendering
* **Physics** — gravity, velocity, acceleration, drag, and speed control
* **Collision** — configurable collision filters and callbacks
* **World System** — static world structures and collision handling
* **Asset System** — images, sounds, fonts, sprite packs, and world packs
* **Input** — keyboard, mouse, and text input callbacks
* **Camera** — camera support through HUMP
* **Console & Debugging** — runtime development tools
* **Custom Entity Data** — add whatever your game needs

---

## Quick Start

Add the `KORE/` directory to your LÖVE2D project:

```text
MyGame/
├── main.lua
├── KORE/
└── assets/
    ├── sprites/
    ├── spritepacks/
    ├── sounds/
    ├── fonts/
    └── world/
```

Then:

```lua
local KORE = require("KORE")

function love.load()

    KORE.initAssetsPath("assets")
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
```

That's enough to get the KORE runtime running.

---

## Entities

KORE entities are Lua tables with built-in identity and optional systems.

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

You can add game-specific data without creating additional framework components.

```lua
player.customkeys.coins = player.customkeys.coins + 1
```

---

## Sprite Packs & World Packs

KORE separates visual assets from world data.

**Sprite packs** organize an entity's sprites and animations:

```text
assets/spritepacks/
└── player.lua
```

**World packs** contain static world structures:

```text
assets/world/
└── level1.lua
```

This keeps entity visuals and world geometry independent.

---

## Developer Control

KORE is designed to stay out of the way.

You can build your own:

* Entity architecture
* Gameplay systems
* State machines
* Controllers
* Behaviors
* Data structures
* Game states
* Level systems

KORE provides runtime functionality without requiring you to structure your entire game around it.

---

## Project Structure

KORE is intended to be a **drop-in framework**.

```text
MyGame/
├── main.lua
│
├── KORE/
│   ├── init.lua
│   ├── src/
│   └── libs/
│
└── assets/
```

Your game owns `main.lua` and `assets/`.

KORE owns its runtime code and bundled libraries.

---

## Documentation

The complete guidebook is available here:

**[`docs/Getting_Started.md`](docs/Getting_Started.md)**

It covers:

* Project setup
* Asset paths
* Entities
* Identity and tags
* Custom data
* Controllers and behaviors
* Input
* Sprites and animations
* Sprite packs
* World packs
* Rendering
* Physics
* Collision
* Camera
* Debugging
* Entity methods
* Game loop

---

## Bundled Libraries

KORE includes several libraries for common functionality:

* [anim8](https://github.com/kikito/anim8)
* [bump.lua](https://github.com/kikito/bump.lua)
* [HUMP](https://github.com/vrld/hump)

They are exposed through:

```lua
KORE.libs
```

---

## Why KORE?

KORE is built around a simple principle:

> **The framework should provide tools, not dictate the game.**

If you need something KORE doesn't provide, you can implement it yourself using normal Lua.

If you don't need a KORE system, you don't have to build your game around it.

---

## Status

KORE is actively developed and its API may change between snapshots.

For the most accurate behavior, refer to the current source code and documentation.

---

## License

See [`LICENSE`](LICENSE) for license information.

---

## Feedbacks

Contact me at hhallcyonn@gmail.com and share your thoughts about anything.