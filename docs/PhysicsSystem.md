**Physics System**

The Physics System handles velocity, force, gravity, drag, and speed limiting for entities that have a `physics` table. It is a simple custom solver (not Box2D) and works together with the World System (which applies the resulting velocity and resolves collisions via bump.lua).

It lives in `src/PhysicsSystem.lua` and is exposed as `KORE.Physics`.

This documentation reflects **Version 3.15**.

---

### Global Settings

| Property          | Default | Description |
|-------------------|---------|-------------|
| `worldgravity`    | `500`   | Downward acceleration applied to Dynamic bodies |
| `worlddrag`       | `300`   | Air resistance / linear damping factor |
| `worldfriction`   | `400`   | Used by the World System during collisions (not applied here) |
| `enabled`         | `true`  | Master switch for the entire physics update |

These values can be changed at runtime:

```lua
KORE.Physics:setWorldGravity(800)
KORE.Physics:setWorldDrag(200)
KORE.Physics:setWorldFriction(500)

-- or via the convenience function in the main module
KORE.setWorldPhysics("gravity", 800)
KORE.setWorldPhysics("drag", 200)
KORE.setWorldPhysics("friction", 500)
```

#### Enabling / Disabling Physics

```lua
KORE.enablePhysics(false)   -- completely skips the update
KORE.enablePhysics(true)
```

When disabled, a log message is printed once.

---

### How the Update Works

`PhysicsSystem.update(entitylist, dt)` is called every frame from `KORE.update`.

It only processes entities that have a `physics` table.

#### Dynamic Bodies

For each Dynamic body that is **not** anchored:

1. **Force → Acceleration**  
   `ax = force.x / mass`  
   `ay = force.y / mass`

2. **Gravity**  
   `ay = ay + (worldgravity * gravityScale)`

3. **Integrate velocity**  
   `nextVel = currentVel + acceleration * dt`

4. **Over-speed handling** (optional)
   - `"damp"` — prevents the velocity from increasing further once `maxSpeed` is exceeded
   - `"clamp"` — hard-clamps the velocity to `±maxSpeed`

5. **Drag**  
   Multiplies both velocity components by  
   `max(0, 1 - (worlddrag * dragScale * dt))`

6. **Clear force**  
   `force.x` and `force.y` are reset to 0 after integration (forces are impulse-like and must be re-applied each frame if continuous force is desired).

If the body is **anchored**, velocity and force are forced to zero.

#### Kinematic Bodies

Only the `anchored` flag is respected.  
If anchored, velocity is set to zero.  
Otherwise the velocity is left untouched (the World System will move the entity).

#### Static Bodies

Completely ignored by the Physics System.

---

### Entity Physics Table (reminder)

Created by the ECS when you pass a `physics` table to `spawnEntity` / `createentity`.

**Dynamic**
```lua
{
    bodytype       = "Dynamic",
    velocity       = {x = 0, y = 0},
    force          = {x = 0, y = 0},
    mass           = 1,
    gravityScale   = 1,
    dragScale      = 1,
    frictionScale  = 1,
    maxSpeed       = {x = 1000, y = 2000},
    grounded       = false,
    anchored       = false,
    overSpeedMode  = "clamp"   -- or "damp"
}
```

**Kinematic**
```lua
{
    bodytype      = "Kinematic",
    velocity      = {x = 0, y = 0},
    anchored      = false,
    frictionScale = 1
}
```

**Static**
```lua
{
    bodytype      = "Static",
    anchored      = true,
    frictionScale = 1
}
```

---

### Interaction with the World System

The Physics System only updates **velocity**.  
Actual position change and collision response are handled later in the same frame by `WorldSystem.update`:

1. Physics System calculates new velocities.
2. World System moves entities using those velocities and resolves collisions with bump.lua.
3. Collision response may zero or reverse velocity components and set the `grounded` flag.

Friction from the World System is applied during collisions using `worldfriction * combinedFrictionScale`.

---

### Useful Entity Methods Related to Physics

These are defined in EntityMethods and are the preferred way to interact with physics from game code:

- `entity:applyForce(fx, fy)`
- `entity:applyImpulse(ix, iy)`
- `entity:setVelocity(vx, vy)`
- `entity:stop()`
- `entity:clearForces()`
- `entity:setAnchored(bool)`
- `entity:isAnchored()`
- `entity:isGrounded()`
- `entity:onGrounded(callback, dt)`
- `entity:followTo(target, speed, dt)`
- `entity:setPhysics(key, value)`
- `entity:setBodytype(data)`

---