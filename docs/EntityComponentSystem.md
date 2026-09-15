**Entity Component System (ECS)**

The ECS is the core of KORE’s entity management. It is a lightweight, table-based system written in pure Lua. Entities are plain tables with an optional set of fields (identity, physics, sprite, animations, events, etc.). There is no strict component class hierarchy — you simply include the data you need when creating an entity.

The system lives in `src/EntityComponentSystem.lua` and is exposed as `KORE.ECS`.  
Entity methods (helper functions attached to every entity) live in `src/EntityMethods.lua`.

---

### Core Data Structures

#### Global Entity Storage
```lua
ECS.entities = {}   -- [id] = entity
ECS.nextId = 1      -- auto-incrementing ID counter
```

#### Entity Structure (created by `ECS.createentity`)

Every entity is a table with a metatable that includes all methods from `EntityMethods`.

Common fields that may be present:

| Field              | Description |
|--------------------|-------------|
| `alive`            | Boolean. When set to `false`, the entity is scheduled for removal. |
| `identity`         | Table containing `id`, `name`, and `tags`. |
| `state`            | String (default `"idle"`). Often used for animation/state machines. |
| `x`, `y`           | Position. |
| `facing`           | Number (default `1`). Usually used for sprite flipping. |
| `lifetime`         | Optional number. Counts down; entity dies when ≤ 0. |
| `physics`          | Optional physics data (see Physics section). |
| `health`           | Optional health data. |
| `input`            | Optional custom input table. |
| `sprite`           | Optional static image (`{type = "image", image = Image}`). |
| `animations`       | Optional table of anim8 animations loaded from a sprite pack. |
| `animdata`         | `{ current = string or nil }` — currently playing animation name. |
| `events`           | Table of callback functions (see Events). |
| `timers`           | Table of active timer handles. |
| `customkeys`       | Free-form table for any game-specific data. |
| `collider`         | Collision box data. |
| `drawdata`         | Rendering parameters (size, origin, layer, scale, etc.). |

---

### Creating and Registering Entities

#### `ECS.createentity(data)`
Creates a new entity from a data table but does **not** add it to the world yet.

- Generates a unique `identity.id`.
- Ensures the name is unique (appends `_1`, `_2`, … if needed).
- Fills in defaults for missing fields.
- Attaches all entity methods.
- Returns the entity table (or `nil` if no data was provided).

#### `ECS.register(entity)`
Adds the entity to `ECS.entities` and immediately calls `WorldSystem.addtoworld(entity)`.

#### Convenience wrapper (recommended)
```lua
local entity = KORE.spawnEntity(data)
-- Internally does: createentity → register
```

---

### Identity System

```lua
entity.identity = {
    id   = number,          -- unique, auto-assigned
    name = string,          -- unique among living entities
    tags = { [string] = true, ... }
}
```

- Names are automatically made unique at creation time.
- Tags are a simple set (presence = true).

#### Looking up entities
```lua
ECS.getEntityByIdentity("id",   42)
ECS.getEntityByIdentity("name", "player")
ECS.getEntityByIdentity("tag",  "enemy")   -- returns the first match
```

---

### Physics Data (when present)

Created only if `data.physics` is supplied.

**Dynamic**
```lua
{
    bodytype       = "Dynamic",
    velocity       = {x = 0, y = 0},
    force          = {x = 0, y = 0},
    mass           = number (default 1),
    gravityScale   = number (default 1),
    dragScale      = number (default 1),
    frictionScale  = number (default 1),
    maxSpeed       = {x = 1000, y = 2000},
    grounded       = false,
    anchored       = false,
    overSpeedMode  = "clamp" | "damp"
}
```

**Kinematic**
```lua
{
    bodytype      = "Kinematic",
    velocity      = {x, y},
    anchored      = false,
    frictionScale = number
}
```

**Static**
```lua
{
    bodytype      = "Static",
    anchored      = true,
    frictionScale = number
}
```

Unknown body types fall back to Static (with a warning).

---

### Health

```lua
entity.health = {
    current        = number (default 100),
    max            = number (default 100),
    dying          = false,
    dyingduration  = number (default 0)
}
```

When `current ≤ 0` and not already dying:
1. `dying` is set to `true`
2. `events.onDeath` is called
3. After `dyingduration` seconds the entity is marked `alive = false`

---

### Events (Callbacks)

All events default to empty functions if not provided.

| Event              | Signature                     | When it runs |
|--------------------|-------------------------------|--------------|
| `beforeupdanim`    | `(entity, dt)`                | Just before the current animation is updated |
| `controller`       | `(entity, dt)`                | Every frame if the entity has physics and is not anchored |
| `behavior`         | `(entity, dt)`                | Every frame |
| `onKeyPressed`     | `(key, entity)`               | On key press |
| `onKeyReleased`    | `(key, entity)`               | On key release |
| `onMousePressed`   | `(x, y, button, entity)`      | On mouse press |
| `onDeath`          | `(entity, dt)`                | When health reaches zero |
| `onCollision`      | `(item, other, dt)`           | When a collision occurs (called on both entities) |

---

### Collider

```lua
entity.collider = {
    collision       = true,          -- whether it participates in collision
    collisionfilter = "slide",       -- "slide" | "touch" | "bounce"
    offsetx         = 0,
    offsety         = 0,
    width           = number,        -- defaults to sprite width or 50
    height          = number         -- defaults to sprite height or 50
}
```

---

### Draw Data

```lua
entity.drawdata = {
    drawable = true,
    width, height,
    r, sx, sy, ox, oy, kx, ky,
    layer = "world"          -- "background" | "world" | "foreground" | "ui"
}
```

---

### Update Loop (`ECS.update(dt, entity)`)

Called every frame for every living entity. Order of operations:

1. Update current animation (if any) and call `beforeupdanim`
2. Call `controller` (only if physics exists and not anchored)
3. Call `behavior`
4. Tick `lifetime` (kill if ≤ 0)
5. Handle health → death transition

Dead entities are cleaned up later by `ECS.removeDeadEntities()`.

---

### Removal

- Setting `entity.alive = false` schedules the entity for removal.
- `ECS.removeDeadEntities()` (called at the end of every `KORE.update`):
  - Disables collision
  - Removes from the bump world
  - Cancels all timers belonging to the entity
  - Deletes it from `ECS.entities`
- `ECS.clearAllentities()` marks every entity as dead (they are removed on the next cleanup pass).

---

### Entity Methods

Every entity created by `createentity` receives a large set of helper methods from `EntityMethods.lua`. Notable ones include:

- Movement / physics helpers: `applyForce`, `applyImpulse`, `followTo`, `setPhysics`, `setBodytype`, `clearForces`, `onGrounded`
- Animation helpers: `switchAnimation`, `pauseCurrentAnim`, `resumeCurrentAnim`, `enteredFrame`, `addAnimCapability`, `changeAnimPack`
- Sprite helpers: `addSpriteCapability`, `changeSprite`, `removeSpriteCapability`
- Spatial helpers: `getCenter`, `distanceToSquared`, `distanceToAxes`, `angleTo`, `lookAt`, `setPosition`
- Lifecycle: `Destroy` (sets `alive = false` and cancels timers)
- State: `setState`

(These will be documented in more detail in the EntityMethods documentation.)

---

### Typical Usage

```lua
local player = KORE.spawnEntity({
    name = "player",
    x = 100,
    y = 200,
    tags = { player = true },
    physics = {
        bodytype = "Dynamic",
        mass = 1,
        maxSpeed = { x = 300, y = 800 }
    },
    animationpack = "player",
    events = {
        controller = function(e, dt)
            -- movement code
        end,
        behavior = function(e, dt)
            -- AI / logic
        end,
        onCollision = function(self, other, dt)
            -- reaction
        end
    },
    customkeys = {
        coins = 0,
        canDash = true
    }
})
```

---