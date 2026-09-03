# Kreator Oriented Runtime Engine

<p align="center">
  <img width= "%60" alt="15595a26-48e3-45f5-8ba6-c159fe6b0abf" src="https://github.com/user-attachments/assets/63626f0d-bf6e-4f51-8eb3-07329925cf58"
</p>


A reusable and flexible game framework built on top of LÖVE 2D.

## Table of Contents

## Overview

**KORE** is a lightweight game framework for [LÖVE 2D](https://love2d.org/) that provides a clean, easy-to-understand hybrid entity-component system. It handles entity creation, input, physics, rendering, and asset management with minimal boilerplate.

The framework is designed for flexibility—you can override almost anything to suit your game's needs.

BE WARNED THAT THIS FRAMEWORK DOES NOT INCLUDE UI HANDLING.

## Features


## Entity System

### Entity Types

KORE defines 5 entity types, each with different capabilities:

| Type | Moves | Collides | Health | Player Input |
|------|-------|----------|--------|--------------|
| **Structure** | ✗ | ✓ | ✗ | ✗ |
| **Particle** | ✓ | ✗ | ✗ | ✗ |
| **Object** | ✓ | ✓ | ✗ | ✗ |
| **NPC** | ✓ | ✓ | ✓ | ✗ |
| **Player** | ✓ | ✓ | ✓ | ✓ |

**Design Philosophy:** Everything is overridable. If the default behavior doesn't fit your needs, you can customize it.

### Entity Components

Each entity can have the following components:


### Entity Methods

Entities come with built-in utility methods:

```lua
entity:moveTo(target, speed, dt) -- Move entity toward a target
entity:faceTo(target)            -- Face toward a target
entity:setState("running")       -- Change the animation state
entity:enteredFrame(1)            -- Check whether an animation entered a frame
entity:Destroy()                  -- Mark the entity for removal
entity:distance(target)           -- Get the distance to another entity
```

### Entity Organization

Entities are stored in three batches for efficient lookup and management:


## Getting Started

### Prerequisites

  - [HUMP](https://github.com/vrld/hump) — Game utilities (vector math, gamestate, class system)
  - [anim8](https://github.com/kikito/anim8) — 2D animation library
  - [BUMP](https://github.com/kikito/bump.lua) — 2D collision detection

### Installation

1. Clone the repository:
```bash
git clone https://github.com/Hhalcyonn/L2D-BootlegSet.git
cd L2D-BootlegSet
```

2. Run with LÖVE:
```bash
love .
```

## Using as a Framework

**KORE** is designed to be used as a reusable framework that you can drop into your own projects.

### Setup in Your Game

1. Copy the `KORE` folder into your game project
2. Create your `main.lua` that imports the framework using the `KORE.lua`:

```lua
local KORE = require("KORE")

function love.load()
  KORE.initAssetsPath({
    spritefolder = "assets/sprites",
    spritepacksfolder = "assets/spritepacks",
    worldpackfolder = "assets/WorldPack",
    soundfolder = "assets/sounds",
    fontfolder = "assets/fonts"
  })
    KORE.load()
    -- ... rest of your game code
end

function love.update(dt)
    KORE.update(dt)
    -- ... your update logic
end

function love.draw()
    KORE.draw()
    -- ... your draw logic
end
```

### Full Example

See **[MAIN_LUA_EXAMPLE.md](MAIN_LUA_EXAMPLE.md)** for a complete example of how to structure your `main.lua` file with the framework.

### Framework Modules

The `KORE.lua` handles all framework modules:

- `ECS` - Entity Component System
- `AssetsSystem` - Asset and animation management
- `WorldSystem` - BUMP collision and world management
- `RenderSystem` - Entity rendering
- `Console` - Debug and spawn commands
- `Physics` - Gravity and drag helpers
- `Prefabs` - Example entity creation helpers


## Architecture

### Rendering & Collision

Unlike traditional ECS systems, **rendering and collision are handled separately**:


This separation keeps the core ECS lean while providing essential game features.

## Console & Debugging

KORE includes a built-in console with useful debug commands:

```lua
kill <name>              -- Kill a specific entity by name
kill all                 -- Kill all entities
kill type <type>         -- Kill all entities of a type
kill subtype <subtype>   -- Kill all entities with a subtype name

spawn <prefab_name>      -- Create an entity from a prefab

debug true/false         -- Toggle debug mode
```

## Asset System

Initialize asset folders before loading the framework:

```lua
KORE.initAssetsPath({
  spritefolder = "assets/sprites",
  spritepacksfolder = "assets/spritepacks",
  worldpackfolder = "assets/WorldPack",
  soundfolder = "assets/sounds",
  fontfolder = "assets/fonts"
})
KORE.load()
```

KORE loads images, initializes the world, and starts the console during `KORE.load()`.

## Math Helpers

KORE does not currently export a `Utils` module. Use the included HUMP vector library for vector math:

```lua
local Vector = require("libs/hump/vector")
local v = Vector(10, 20)
v:normalized()
```

## License

KORE is provided as-is for learning and game development purposes. Feel free to modify, use and improve it!

This project uses the following open-source libraries:


**Questions or contributions?** Feel free to open an issue or pull request!
