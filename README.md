<p align="center">
  <img width="80%" alt="file_00000000f7a08230af9d8c43de14b487" src="https://github.com/user-attachments/assets/63626f0d-bf6e-4f51-8eb3-07329925cf58" />
</p>
# Kreator Oriented Runtime Engine

A reusable and flexible game framework built on top of LÖVE 2D.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Entity System](#entity-system)
- [Getting Started](#getting-started)
- [Using as a Framework](#using-as-a-framework)
- [Architecture](#architecture)
- [Console & Debugging](#console--debugging)
- [Utilities](#utilities)
- [License](#license)

## Overview

**KORE** is a lightweight game framework for [LÖVE 2D](https://love2d.org/) that provides a clean, easy-to-understand hybrid entity-component system. It handles entity creation, input, physics, rendering, and asset management with minimal boilerplate.

The framework is designed for flexibility—you can override almost anything to suit your game's needs.

BE WARNED THAT THIS FRAMEWORK DOES NOT INCLUDE UI HANDLING.

## Features

- **Simple Entity-Component System** — Create entities with minimal setup
- **Organized Entity Management** — Entities sorted by type and name for fast lookups
- **Built-in Physics & Rendering** — BUMP collision handling and render component system
- **Console Commands** — Debug and spawn entities at runtime
- **Asset Management** — Automatic animation and asset pack loading
- **Utility Functions** — Distance calculations, lerp, clamping, vector math via HUMP
- **Modular `init.lua`** — Import the entire framework with a single `require()` call

## Entity System

### Entity Types

L2D-BootlegSet defines 5 entity types, each with different capabilities:

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

- **`Controller`** — Handles input and decision-making
- **`Behavior`** — Defines entity behavior logic
- **`BeforeUpdateAnim`** — Animation update logic (all entity types)
- **`BeforeDying`** — Cleanup logic before death (NPC and Player only)
- **`CollisionLogic`** — Collision response logic (all except Particles)
- **`KeyPressFunction`** — Keyboard input handling (Player only)
- **`MousePressFunction`** — Mouse input handling (Player only)

### Entity Methods

Entities come with built-in utility methods:

```lua
entity:moveTo(target)      -- Move entity to target position
entity:faceTo(target)      -- Face toward target
```

### Entity Organization

Entities are stored in three batches for efficient lookup and management:

- **`Entities`** — All entities in the game
- **`TypeBatch`** — Entities grouped by type
- **`SubtypeBatch`** — Entities grouped by name

## Getting Started

### Prerequisites

- LÖVE 2D (0.10.x or higher)
- Required libraries (included):
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
-- main.lua
local KORE = require("KORE/KORE")

function love.load()
    -- Access framework modules
    KORE.load()
    -- ... rest of your game code
end

function love.update(dt)
    KORE.update()
    -- ... your update logic
end

function love.draw()
    KORE.drawinworld()
    KORE.drawonscreen()
    -- ... your draw logic
end
```

### Full Example

See **[MAIN_LUA_EXAMPLE.md](MAIN_LUA_EXAMPLE.md)** for a complete example of how to structure your `main.lua` file with the framework.

### Framework Modules

The `KORE.lua` handles all framework modules:

- **`ECS`** — Entity Component System
- **`AssetsSystem`** — Asset and animation management
- **`WorldSystem`** — Physics and collision system
- **`RenderSystem`** — Entity rendering
- **`Console`** — Debug console
- **`Physics`** — Physics utilities (gravity, drag, etc)
- **`Prefabs`** — Prefab entity creation
- **`Utils`** — Utility functions

## Architecture

### Rendering & Collision

Unlike traditional ECS systems, **rendering and collision are handled separately**:

- **`RenderComponentSystem`** — Handles all entity drawing
- **`WorldComponentSystem`** — Handles BUMP collision detection and physics

This separation keeps the core ECS lean while providing essential game features.

## Console & Debugging

L2D-BootlegSet includes a built-in console with useful debug commands:

```lua
kill <name>              -- Kill a specific entity by name
kill all                 -- Kill all entities
kill type <type>         -- Kill all entities of a type
kill subtype <subtype>   -- Kill all entities with a subtype name

spawn <prefab_name>      -- Create an entity from a prefab

debug true/false         -- Toggle debug mode
```

## Utilities

### Asset System

Automatically load animations and asset packs:

```lua
assetSystem:loadPack(pack, packType)
```

This function sets up `anim8` animations and worldpacks from your spritepack and worldpack data modules.

### Helper Functions

Common utility functions in `utils.lua`:

```lua
distance(obj1, obj2)     -- Calculate distance between two objects
lerp(a, b, t)            -- Linear interpolation
clamp(value, min, max)   -- Clamp value between min and max
splitName(name)          -- Split entity unique names
```

For advanced math, use **HUMP's vector library**:

```lua
local Vector = require 'hump.vector'
local v = Vector(10, 20)
v:normalized()
```

## License

KORE is provided as-is for learning and game development purposes. Feel free to modify and improve it!

This project uses the following open-source libraries:
- [HUMP](http://hump.readthedocs.org) — MIT License
- [anim8](https://github.com/kikito/anim8) — ZLIB License
- [BUMP](https://github.com/kikito/bump.lua) — MIT License

---

**Questions or contributions?** Feel free to open an issue or pull request!
