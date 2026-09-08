# Getting Started with KORE

KORE (**Kreator Oriented Runtime Engine**) is a LÖVE 2D framework built around giving the game developer control over their entities, systems, assets, and game loop.

KORE is designed to be **dropped into a LÖVE project as a dependency**. Your game owns its assets and game code; KORE provides the runtime systems.

---

## 1. Project Structure

A typical project using KORE looks like this:

```text
MyGame/
├── main.lua
├── conf.lua
├── KORE/
│   ├── init.lua
│   ├── src/
│   │   ├── EntityComponentSystem.lua
│   │   ├── EntityMethods.lua
│   │   ├── AssetsSystem.lua
│   │   ├── WorldSystem.lua
│   │   ├── RenderSystem.lua
│   │   ├── Console.lua
│   │   └── PhysicsSystem.lua
│   └── libs/
└── assets/
    ├── sprites/
    │    └── .png
    ├── spritepacks/
    │    └── .lua
    ├── sounds/
    │    └── .wav/.mp3/etc.
    ├── fonts/
    │    └── .ttf
    └── world/
        └── .lua
```

KORE does not require your game to reorganize its own source code around KORE.

The `KORE/` directory contains the framework.

The `assets/` directory belongs to your game.

---

## 2. Importing KORE

In your `main.lua`:

```lua
local KORE = require("KORE")
```

The framework exposes its main systems through the returned `KORE` table:

```lua
KORE.ECS
KORE.AssetsSystem
KORE.WorldSystem
KORE.RenderSystem
KORE.ConsoleSystem
KORE.Physics
```

The asset tables are also available directly through KORE:

```lua
KORE.images
KORE.sounds
KORE.fonts
```

The bundled libraries are available through:

```lua
KORE.libs.anim8
KORE.libs.bump
KORE.libs.camera
KORE.libs.timer
KORE.libs.vector
KORE.libs.class
KORE.libs.gamestate
```

---

## 3. Your `main.lua`

The simplest KORE game forwards the LÖVE callbacks to KORE:

```lua
local KORE = require("KORE")

function love.load()

    KORE.initAssetsPath({
        spritefolder = "assets/sprites",
        spritepacksfolder = "assets/spritepacks",
        worldpackfolder = "assets/world",
        soundfolder = "assets/sounds",
        fontfolder = "assets/fonts"
    })

    KORE.load()
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

function love.textinput(text)
    KORE.textinput(text)
end

function love.textedited(text, start, length)
    KORE.textedited(text, start, length)
end
```

### What each function does

| Function                               | Purpose                                                                                          |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `KORE.setCamera()`                     | Creates and returns the bundled HUMP camera.                                                     |
| `KORE.initAssetsPath(context)`         | Configures the directories used by the asset system.                                             |
| `KORE.load()`                          | Loads initial assets, registers entities with an initialized world, and initializes the console. |
| `KORE.update(dt)`                      | Updates timers, physics, entities, console, world movement, and dead-entity removal.             |
| `KORE.draw()`                          | Draws entities, debug information, and the console.                                              |
| `KORE.keypressed(key)`                 | Sends keyboard presses to the console and entities.                                              |
| `KORE.keyreleased(key)`                | Sends keyboard releases to the console and entities.                                             |
| `KORE.textinput(text)`                 | Sends text input to the console.                                                                 |
| `KORE.textedited(text, start, length)` | Sends text-edit events to the console.                                                           |

The normal LÖVE lifecycle is therefore:

```text
love.load()
    └── KORE.load()

love.update(dt)
    └── KORE.update(dt)

love.draw()
    └── KORE.draw()
```

---

## 4. Asset Paths

KORE's asset system uses these default directories:

```text
assets/sprites
assets/spritepacks
assets/world
assets/sounds
assets/fonts
```

You can override them with `KORE.initAssetsPath()`:

```lua
KORE.initAssetsPath({
    spritefolder = "assets/sprites",
    spritepacksfolder = "assets/spritepacks",
    worldpackfolder = "assets/world",
    soundfolder = "assets/sounds",
    fontfolder = "assets/fonts"
})
```

You only need to specify the paths you want to change. Missing values use KORE's defaults.

### Loading assets

```lua
KORE.AssetsSystem.loadimages()
KORE.AssetsSystem.loadsounds()
KORE.AssetsSystem.loadfonts()
```

The loaded assets are stored in:

```lua
KORE.images
KORE.sounds
KORE.fonts
```

Asset filenames are available using their original filename and their lowercase key.

For example, an image named `Player.png` can be accessed as:

```lua
KORE.images["Player.png"]
KORE.images["player.png"]
```

### Reloading assets

Reload everything:

```lua
KORE.AssetsSystem.reloadassets()
```

Reload only one category:

```lua
KORE.AssetsSystem.reloadassets("images")
KORE.AssetsSystem.reloadassets("sounds")
KORE.AssetsSystem.reloadassets("fonts")
```
# Sprite Packs and World Packs

KORE has two special types of asset packs:

* **Sprite packs** — define sprites and animations.
* **World packs** — define static world structures used by the World System.

Both are Lua files stored in their respective asset directories.

---

## Sprite Packs

A sprite pack is a Lua file stored in:

```text
assets/spritepacks/
```

It describes the sprites and animations that an entity can use.

For example:

```text
assets/
└── spritepacks/
    └── player.lua
```

A sprite pack can contain multiple animations or images:

```lua
return {

    idle = {
        type = "animation",
        image = "player.png",

        frameWidth = 32,
        frameHeight = 32,

        frames = "1-4",
        row = 1,

        speed = 0.1
    },

    run = {
        type = "animation",
        image = "player.png",

        frameWidth = 32,
        frameHeight = 32,

        frames = "1-6",
        row = 2,

        speed = 0.08
    },

    portrait = {
        type = "image",
        image = "player.png"
    }

}
```

The pack can then be assigned to an entity:

```lua
local player = KORE.spawnEntity({

    name = "player",

    animationpack = "player.lua",

    state = "idle"

})
```

The entity's `state` determines which animation or sprite entry is currently being used:

```lua
player:setState("run")
```

This allows one sprite pack to contain an entity's complete set of visual states instead of loading each animation separately.

### Why use a sprite pack?

Without a pack, an entity would need to have its visual information configured individually.

A sprite pack lets you organize related visual states together:

```text
player.lua
├── idle
├── run
├── jump
├── fall
└── attack
```

The entity can then switch between them using its state:

```lua
player:setState("idle")
player:setState("run")
player:setState("jump")
player:setState("attack")
```

---

## World Packs

A world pack is a Lua file stored in:

```text
assets/world/
```

World packs describe static structures that KORE's `WorldSystem` can load into the collision world.

For example:

```text
assets/
└── world/
    └── level1.lua
```

A world pack is loaded as a `"world"` pack:

```lua
local worldpack = KORE.AssetsSystem.loadpack(
    "level1.lua",
    "world"
)
```

The resulting world data can then be passed to:

```lua
KORE.WorldSystem.initworld(64, worldpack)
```

The first argument is the world cell size.

The second argument is the loaded world-pack data.

### What a world pack is for

A world pack is intended for **static world geometry or structures** that need to exist in the collision world.

This separates level/world data from the entity system.

For example, a game could organize its world assets as:

```text
assets/
└── world/
    ├── level1.lua
    ├── level2.lua
    └── testroom.lua
```

Each file can represent a different world configuration.

---

## Sprite Packs vs World Packs

The two pack types serve different purposes:

| Pack        | Directory             | Purpose                                             |
| ----------- | --------------------- | --------------------------------------------------- |
| Sprite pack | `assets/spritepacks/` | Entity visuals, sprites, and animations             |
| World pack  | `assets/world/`       | Static world structures used by the collision world |

A sprite pack answers:

> **"What should this entity look like?"**

A world pack answers:

> **"What static structures exist in this world?"**

They are independent systems.

An entity can use a sprite pack without a world pack, and a world can exist without entities having animated sprites.

---

## Loading Packs Manually

KORE exposes the pack loader through the asset system:

```lua
KORE.AssetsSystem.loadpack(packName, packtype)
```

For a sprite/animation pack:

```lua
local pack = KORE.AssetsSystem.loadpack(
    "player.lua",
    "anim8anim"
)
```

For a world pack:

```lua
local pack = KORE.AssetsSystem.loadpack(
    "level1.lua",
    "world"
)
```

In normal entity creation, you usually do not need to manually load an animation pack. You can provide:

```lua
animationpack = "player.lua"
```

when creating the entity, and KORE loads the animation pack for the entity.

World packs, however, are used by the `WorldSystem` when initializing a world.

---

# 5. Creating Entities

KORE's ECS is centered around:

```lua
KORE.ECS.createentity(data)
```

For example:

```lua
local player = KORE.ECS.createentity({
    name = "player",
    x = 100,
    y = 100
})

KORE.ECS.register(player)
```

Or use KORE's convenience function:

```lua
local player = KORE.spawnEntity({
    name = "player",
    x = 100,
    y = 100
})
```

`spawnEntity()` creates the entity and immediately registers it with the ECS.

---

## 6. Entity Identity

Every entity has an identity containing:

```lua
entity.identity.name
entity.identity.id
entity.identity.tags
```

Names are automatically made unique.

Tags are completely developer-defined.

For example:

```lua
local enemy = KORE.spawnEntity({
    name = "goblin",

    tags = {
        enemy = true,
        hostile = true,
        boss = false
    }
})
```

You can retrieve identity information with:

```lua
enemy:getIdentity("name")
enemy:getIdentity("id")
enemy:getIdentity("tag", "enemy")
```

Or retrieve all three:

```lua
local name, id, tags = enemy:getIdentity("all")
```

Entities can also be searched through the ECS:

```lua
KORE.ECS.getEntityByIdentity("name", "goblin")
KORE.ECS.getEntityByIdentity("id", 1)
KORE.ECS.getEntityByIdentity("tag", "enemy")
```

Tags are not restricted to predefined categories. You can create whatever tags your game needs.

---

# 7. Entity Data

`createentity()` accepts optional data.

A basic entity can start with:

```lua
local entity = KORE.spawnEntity({
    name = "player",
    x = 100,
    y = 200,

    facing = 1,
    state = "idle",

    tags = {
        player = true
    }
})
```

KORE entities are intentionally open-ended. You can attach additional data to an entity without needing to create a separate component type for every piece of information.

---

## Lifetime

Entities can have a limited lifetime:

```lua
local particle = KORE.spawnEntity({
    lifetime = 2
})
```

The entity is marked dead when its lifetime reaches zero and is removed during the ECS cleanup phase.

---

## Health

Entities can optionally have health:

```lua
local enemy = KORE.spawnEntity({
    health = {
        current = 100,
        max = 100,
        dyingduration = 1
    }
})
```

You can also provide a death callback:

```lua
local enemy = KORE.spawnEntity({
    health = {
        current = 100,
        max = 100,
        dyingduration = 1
    },

    onDeath = function(entity, dt)
        print("Enemy died")
    end
})
```

---

# 8. Controllers and Behaviors

Entities can have a controller:

```lua
local entity = KORE.spawnEntity({
    controller = function(entity, dt)
        entity.x = entity.x + 100 * dt
    end
})
```

Controllers are intended for active entity control such as player movement or AI.

Entities can also have a behavior:

```lua
local entity = KORE.spawnEntity({
    behavior = function(entity, dt)
        -- Custom per-frame behavior
    end
})
```

These callbacks are intentionally open-ended.

You decide what the entity does.

---

# 9. Input Callbacks

Entities can directly receive input events.

```lua
local player = KORE.spawnEntity({

    onKeyPressed = function(key, entity)

        if key == "space" then
            print("Jump")
        end

    end,

    onKeyReleased = function(key, entity)

        print("Released:", key)

    end,

    onMousePressed = function(x, y, button, entity)

        print("Mouse:", x, y, button)

    end
})
```

KORE forwards the corresponding LÖVE input callbacks to registered entities.

---

# 10. Sprites

A static sprite can be assigned when creating an entity:

```lua
local player = KORE.spawnEntity({
    sprite = "player.png"
})
```

The image must exist in the configured sprite directory.

---

# 11. Animations

Animation packs can be loaded from the configured spritepack directory.

For example:

```lua
local player = KORE.spawnEntity({
    animationpack = "player.lua",
    state = "idle"
})
```

An animation pack can contain entries such as:

```lua
return {

    idle = {
        type = "animation",
        image = "player.png",

        frameWidth = 32,
        frameHeight = 32,

        frames = "1-4",
        row = 1,

        speed = 0.1
    },

    icon = {
        type = "image",
        image = "player.png"
    }

}
```

Animated entities use `entity.state` to select the current animation:

```lua
entity:setState("idle")
```

When changing to a new animation state, KORE resets that animation to its first frame.

You can detect when an animation enters a specific frame:

```lua
if entity:enteredFrame(3) then
    -- Frame 3 was entered
end
```

This can be useful for animation-driven events:

```lua
if entity:enteredFrame(3) then
    -- Play a sword swing sound
end
```

---

# 12. Drawing

Entities contain drawing information in:

```lua
entity.drawdata
```

For example:

```lua
local entity = KORE.spawnEntity({

    drawdata = {
        drawable = true,

        width = 64,
        height = 64,

        r = 0,

        sx = 1,
        sy = 1,

        ox = 32,
        oy = 32,

        layer = "world"
    }

})
```

The drawing data controls things such as:

* Drawable state
* Width
* Height
* Rotation
* Scale
* Origin
* Rendering layer

---

## Rendering Layers

KORE supports these layers:

```text
background
world
foreground
ui
```

For example:

```lua
drawdata = {
    layer = "foreground"
}
```

Entities with an unknown layer fall back to the `world` layer.

---

# 13. Physics

Physics is opt-in.

Create an entity with:

```lua
canPhysics = true
```

For example:

```lua
local player = KORE.spawnEntity({

    canPhysics = true,

    velocityx = 0,
    velocityy = 0,

    gravity = 800,
    dragval = 100,
    maxspeed = 400

})
```

The primary physics fields are:

| Field          | Purpose                                                      |
| -------------- | ------------------------------------------------------------ |
| `velocityx`    | Horizontal velocity.                                         |
| `velocityy`    | Vertical velocity.                                           |
| `gravity`      | Vertical acceleration.                                       |
| `dragval`      | Horizontal drag.                                             |
| `maxspeed`     | Maximum horizontal velocity.                                 |
| `acceleration` | Used by movement helpers such as `moveTo()`.                 |
| `grounded`     | Indicates whether collision placed the entity on the ground. |
| `anchored`     | Prevents the entity controller from running.                 |

KORE's physics system applies gravity, horizontal drag, and the horizontal speed limit.

**`maxspeed` only limits horizontal velocity. Vertical velocity is not clamped by it.**

---

## Changing Physics

Physics can be changed at runtime:

```lua
entity:setPhysics(800, 100, 400)
```

The parameters are:

```text
gravity, dragval, maxspeed, collision
```

You can also use predefined modes.

### Ignore Physics

```lua
entity:setPhysics("ignorephysics")
```

Disables physics processing.

### Ignore Physics but Keep Collision

```lua
entity:setPhysics("ignorephysicsbutcollision")
```

Disables physics behavior while retaining collision.

### Zero Gravity

```lua
entity:setPhysics("zerogravity")
```

Disables gravity.

### No Drag

```lua
entity:setPhysics("nodrag")
```

Disables drag.

### No Maximum Speed

```lua
entity:setPhysics("nomaxspeed")
```

Disables the horizontal maximum-speed limit.

---

# 14. Collision

Entities have a collider:

```lua
entity.collider
```

A collider can be configured when creating the entity:

```lua
local entity = KORE.spawnEntity({

    collider = {
        collision = true,

        collisionfilter = "slide",

        offsetx = 0,
        offsety = 0,

        width = 32,
        height = 32
    }

})
```

---

## Collision Filters

KORE supports:

```text
slide
cross
bounce
touch
```

For example:

```lua
entity:setPhysics("colfilter", "bounce")
```

---

## Enable or Disable Collision

Enable collision:

```lua
entity:setPhysics("collision", true)
```

Disable collision:

```lua
entity:setPhysics("collision", false)
```

---

## Collision Callback

Entities can respond to collisions with:

```lua
local player = KORE.spawnEntity({

    onCollision = function(entity, other, dt)

        print("Collision with", other)

    end

})
```

---

# 15. World System

KORE uses the bundled Bump world for collision movement.

A world can be initialized with:

```lua
KORE.WorldSystem.initworld(64, worldpack)
```

The first argument is the world cell size.

The second argument is the world pack containing structures to register.

The current world can be deleted with:

```lua
KORE.WorldSystem.deleteworld()
```

When a world has been initialized, registered entities can be added to it during `KORE.load()`.

---

# 16. Entity Methods

KORE entities provide methods for common operations:

```lua
entity:moveTo(target, speed, dt)

entity:faceTo(target)

entity:setState("running")

entity:enteredFrame(1)

entity:Destroy()

entity:distanceTo(target)

entity:getVelocities()

entity:getCoordinates()

entity:setPosition(x, y)

entity:setPhysics(...)

entity:getIdentity(...)
```

---

## Movement

Move toward another entity:

```lua
entity:moveTo(target, 200, dt)
```

Or move toward coordinates:

```lua
entity:moveTo({
    x = 500,
    y = 300
}, 200, dt)
```

`moveTo()` works through velocity and can use the entity's acceleration when physics values are present.

---

## Facing

Face toward a target:

```lua
entity:faceTo(target)
```

This changes the entity's drawing rotation toward the target.

---

## Position

Set an entity's position:

```lua
entity:setPosition(100, 200)
```

---

## Velocity

Retrieve the entity's velocity:

```lua
local vx, vy = entity:getVelocities()
```

---

## Coordinates

Retrieve the entity's coordinates:

```lua
local x, y = entity:getCoordinates()
```

---

## Distance

Calculate distance to another entity:

```lua
local distance = entity:distanceTo(other)
```

Or to coordinates:

```lua
local distance = entity:distanceTo(500, 300)
```

---

## Destroying Entities

Destroy an entity with:

```lua
entity:Destroy()
```

This marks the entity as dead.

KORE removes dead entities during its ECS cleanup phase.

---

# 17. Camera

KORE provides a bundled HUMP camera.

Create one with:

```lua
local camera = KORE.setCamera()
```

The camera returned by `setCamera()` can be used normally:

```lua
camera:lookAt(0, 0)
```

For example:

```lua
function love.load()

    camera = KORE.setCamera()

    KORE.load()

end

function love.update(dt)

    KORE.update(dt)

    camera:lookAt(player.x, player.y)

end
```

Remove the active camera with:

```lua
KORE.unsetCamera()
```

When a camera exists, `KORE.draw()` automatically attaches it before world rendering and detaches it afterward.

---

# 18. Debugging

Enable debug rendering with:

```lua
KORE.setDebug(true)
```

Disable it with:

```lua
KORE.setDebug(false)
```

You can check the current debug state:

```lua
local enabled = KORE.getDebug()
```

When debug rendering is enabled, KORE draws additional entity and collider information.

---

# 19. The KORE Game Loop

KORE performs its update operations in a specific order.

```text
KORE.update(dt)
├── HUMP timer
├── PhysicsSystem
├── ECS entity updates
│   ├── animations
│   ├── controllers
│   ├── behaviors
│   ├── lifetime
│   └── health/death
├── Console
├── WorldSystem
└── Remove dead entities
```

Rendering follows its own order:

```text
KORE.draw()
├── camera attach
├── background
├── world
├── foreground
├── ui
├── world debug
├── camera detach
├── screen debug
└── console
```

This means entity controllers and behaviors can modify an entity before the world system performs its movement and collision processing for the frame.

---

# 20. A Minimal Complete Example

A minimal KORE game can be as small as:

```lua
local KORE = require("KORE")

function love.load()

    KORE.spawnEntity({
        name = "player",

        x = 100,
        y = 100,

        sprite = "player.png"
    })

    KORE.load()

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
```

If you are using KORE's default asset directories, you do not need to call `initAssetsPath()`.

If you use different directories, configure them before calling `KORE.load()`:

```lua
KORE.initAssetsPath({
    spritefolder = "my_assets/sprites"
})
```

---

# 21. Running the Game

From the project directory:

```bash
love .
```

LÖVE loads:

```text
main.lua
    └── require("KORE")
```

KORE then provides the systems used by your game.

---

# 22. Using KORE's ECS

KORE's ECS is intentionally lightweight.

An entity does not need to be constructed from a rigid list of component classes.

Instead, entity data can be supplied directly:

```lua
local entity = KORE.spawnEntity({

    name = "enemy",

    x = 100,
    y = 100,

    tags = {
        enemy = true
    },

    health = {
        current = 100,
        max = 100
    },

    canPhysics = true,

    gravity = 800,

    controller = function(entity, dt)

        -- Enemy movement

    end

})
```

This lets you define the data and behavior an entity actually needs.

You are not required to create a separate abstraction for every possible entity feature.

---

# 23. Custom Entity Data

KORE entities can contain custom information.

For example:

```lua
local enemy = KORE.spawnEntity({

    name = "goblin",

    damage = 20,

    faction = "enemy",

    drops = {
        "coin",
        "potion"
    }

})
```

You can then access that data directly:

```lua
print(enemy.damage)
print(enemy.faction)
```

For arbitrary custom values, KORE also provides custom storage through:

```lua
entity.customkeys
```

The exact structure of your game's data is therefore left to you.

---

# 24. Using Bundled Libraries

KORE includes several libraries under:

```lua
KORE.libs
```

For example:

```lua
local timer = KORE.libs.timer
local vector = KORE.libs.vector
local camera = KORE.libs.camera
```

This keeps bundled dependencies inside KORE rather than exposing every library as part of the global namespace.

You can still use these libraries directly when your game needs them.

For example:

```lua
local Vector = KORE.libs.vector

local direction = Vector(1, 0)
```

KORE does not require you to use every bundled library.

---

# 25. KORE's Design Philosophy

KORE is intentionally **not a rigid game architecture**.

The framework provides systems for common functionality:

```text
EntityComponentSystem
AssetsSystem
WorldSystem
RenderSystem
PhysicsSystem
ConsoleSystem
```

But your game remains responsible for deciding how those systems are used.

You are free to:

* Add custom fields to entities.
* Store arbitrary values.
* Add custom systems.
* Write your own controllers.
* Write your own behaviors.
* Use KORE's bundled libraries directly.
* Bypass KORE systems when your game needs different behavior.
* Extend KORE functionality.
* Replace parts of KORE in your project.

KORE provides the machinery.

**You decide the architecture of the game.**

---

# 26. Quick Reference

## KORE

```lua
KORE.load()
KORE.update(dt)
KORE.draw()

KORE.keypressed(key)
KORE.keyreleased(key)

KORE.textinput(text)
KORE.textedited(text, start, length)

KORE.setDebug(value)
KORE.getDebug()

KORE.setCamera()
KORE.unsetCamera()

KORE.initAssetsPath(context)

KORE.spawnEntity(data)
```

## Systems

```lua
KORE.ECS
KORE.AssetsSystem
KORE.WorldSystem
KORE.RenderSystem
KORE.ConsoleSystem
KORE.Physics
```

## Assets

```lua
KORE.images
KORE.sounds
KORE.fonts
```

## Entity Methods

```lua
entity:moveTo(...)
entity:faceTo(...)
entity:setState(...)
entity:enteredFrame(...)
entity:Destroy(...)
entity:distanceTo(...)
entity:getVelocities()
entity:getCoordinates()
entity:setPosition(...)
entity:setPhysics(...)
entity:getIdentity(...)
```

## Libraries

```lua
KORE.libs.anim8
KORE.libs.bump
KORE.libs.camera
KORE.libs.timer
KORE.libs.vector
KORE.libs.class
KORE.libs.gamestate
```

---

# 27. Where to Go Next

Once the basic setup is working, the recommended next step is to build your game's entities using `KORE.spawnEntity()` and gradually introduce the systems your game actually needs.

A typical progression is:

```text
1. Install KORE
       ↓
2. require("KORE")
       ↓
3. Configure assets
       ↓
4. Create entities
       ↓
5. Add sprites/animations
       ↓
6. Add controllers/behaviors
       ↓
7. Enable physics if needed
       ↓
8. Initialize a world for collision
       ↓
9. Add your game's own systems
       ↓
10. Build the game
```

KORE is not intended to dictate what happens at every step.

It exists to give you the runtime tools needed to build the game you want.
