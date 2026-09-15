# KORE

### Kreator Oriented Runtime Engine

A lightweight, developer-controlled **2D drop-in game framework for LÖVE2D**.

KORE provides the runtime systems you need to build a game while keeping your game's architecture in your hands.

**No editor. No mandatory architecture. No unnecessary abstraction.**
---

## Features

* **Entity Component System** — flexible Lua-based ID-keyed entities with automatic unique naming
* **Rendering** — sprites, animations, layers, per-layer shaders and debug rendering
* **Physics** — physics bodies (Dynamic, Kinematic, Static)gravity, velocity, force, acceleration, drag, friction, mass, overspeedmode (Custom, Not Box2D physics.)
* **World System** — collision, collision filters and onCollision callbacks handling
* **Asset System** — automatic loading of images, sounds, fonts, shaders, spritepacks, and worldpacks
* **Input** — keyboard, mouse, and text input callbacks
* **Camera** — camera support through HUMP
* **Console & Debugging** — runtime development tools
* **Custom Entity Data** — add whatever your game needs
* **Entity Methods** — tons of built in methods for every entities
* **Logging** — logs info, debug, warn, error, fail

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
    └── worldpacks/
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

BEWARE! If your assets folder is not like:

```text
assets/
    ├── sprites/
    ├── spritepacks/
    ├── sounds/
    ├── fonts/
    └── worldpacks/
```

You must fill

```lua
KORE.initAssetsPath(
    spritefolder = YourspritefolderPath
    spritepacksfolder = YourspritepcksfolderPath
    worldpackfolder = Your worldpackfolderPath
    soundfolder = YoursoundfolderPath
    fontfolder = YourfontfolderPath
    shaderfolder = YourshaderfolderPath
)
```

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

**Sprite packs** store's anim8 parameter data:

```text
assets/spritepacks/
└── player.lua
```

**World packs** contain entity data's:

```text
assets/worldpack/
└── level1.lua
```

Worldpack is supposed for static structures but..
Because its just raw entity data's, you can use it as a instant load prefab.

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

Your game owns the mechanics, `main.lua` and `assets/`.

KORE owns its runtime code and bundled libraries.

---

## Documentation

Documentation about everything is available here:

**[`docs`](docs)**

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
* Logging

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

Looking for people interested in helping shape KORE.

---

## License

MIT License

See [`LICENSE`](LICENSE) for more information.

---

## Feedbacks

Some of the documentations is mismatched and some codes are incosistent, if anyone could point it out, i'd appreciate it.

Contact me at hhallcyonn@gmail.com  or my discord; **h_halcyon** and share your thoughts about anything.