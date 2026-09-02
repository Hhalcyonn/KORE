# L2D-BootlegSet

A reusable and flexible game framework built on top of LÖVE 2D.

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Entity System](#entity-system)
- [Getting Started](#getting-started)
- [Architecture](#architecture)
- [Console & Debugging](#console--debugging)
- [Utilities](#utilities)
- [License](#license)

## Overview

**L2D-BootlegSet** is a lightweight game framework for [LÖVE 2D](https://love2d.org/) that provides a clean, easy-to-understand hybrid entity-component system. It handles entity creation, input, and updates with minimal boilerplate, making it ideal for rapid game prototyping and development.

The framework is designed for flexibility—you can override almost anything to suit your game's needs.

## Features

- **Simple Entity-Component System** — Create entities with minimal setup
- **Organized Entity Management** — Entities sorted by type and name for fast lookups
- **Built-in Physics & Rendering** — BUMP collision handling and render component system
- **Console Commands** — Debug and spawn entities at runtime
- **Asset Management** — Automatic animation and asset pack loading
- **Utility Functions** — Distance calculations, lerp, clamping, vector math via HUMP

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

### Creating Your First Entity

Define a simple entity in a data module:

```lua
-- entities/player.lua
return {
    name = "player",
    type = "Player",
    x = 100,
    y = 100,
    width = 32,
    height = 32,
    health = 100,
}
```

Spawn it in your game:

```lua
function love.load()
    -- Initialize the framework
    world = World()
    
    -- Spawn player entity
    world:spawn("player", 100, 100)
end

function love.update(dt)
    world:update(dt)
end

function love.draw()
    world:render()
end
```

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

This function sets up `anim8` animations and asset packs from your data modules.

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

L2D-BootlegSet is provided as-is for learning and game development purposes. Feel free to modify and improve it!

This project uses the following open-source libraries:
- [HUMP](http://hump.readthedocs.org) — MIT License
- [anim8](https://github.com/kikito/anim8) — ZLIB License
- [BUMP](https://github.com/kikito/bump.lua) — MIT License

---

**Questions or contributions?** Feel free to open an issue or pull request!

