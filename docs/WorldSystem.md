**World System**

The World System manages spatial collision using **bump.lua**. It is responsible for:

- Creating and destroying the collision world
- Adding / removing entities from the world
- Moving entities according to their velocity
- Resolving collisions
- Updating the `grounded` state
- Applying friction during collisions

It lives in `src/WorldSystem.lua` and is exposed as `KORE.WorldSystem`.

---

### Creating and Destroying the World

```lua
WorldSystem.initworld(cellsize, worldpack)
```

- `cellsize` (optional) — size of the spatial hash cells used by bump (default `64`).
- `worldpack` (optional) — a table of entity data. Each entry is turned into an entity and registered.

Creates a new bump world and optionally loads a set of entities from a world pack.

```lua
WorldSystem.deleteworld()
```

Sets the internal world reference to `nil`. Existing entities are not automatically cleaned up.

---

### Adding / Removing Entities

```lua
WorldSystem.addtoworld(entity)
```

Adds the entity to the bump world if:

- A world exists
- The entity has a `collider`
- `collider.collision` is `true`
- The entity is not already present in the world

The position used is `entity.x + offsetx`, `entity.y + offsety` with the collider’s width and height.

```lua
WorldSystem.removefromworld(entity)
```

Removes the entity from the bump world if it is currently present.

These functions are called automatically by the ECS when entities are registered or marked for removal.

---

### Collision Filter

The internal filter decides how two colliders interact:

| Priority | Result   | Condition |
|----------|----------|---------|
| 1        | `"touch"`  | Either collider has `collisionfilter = "touch"` |
| 2        | `"bounce"` | Either collider has `collisionfilter = "bounce"` |
| 3        | `"slide"`  | Either collider has `collisionfilter = "slide"` (default) |

The filter is passed to `bump.world:move()`.

---

### Update Loop

```lua
WorldSystem.update(entitylist, dt)
```

Called every frame from `KORE.update` after the Physics System has calculated velocities.

For each entity the system:

1. Skips the entity if it has no velocity, is anchored, or is Static.
2. If the entity is in the bump world and has collision enabled:
   - Records the previous `grounded` state and temporarily sets `grounded = false`.
   - Calculates the goal position: `x + vx * dt`, `y + vy * dt`.
   - Calls `world:move()` with the collision filter.
   - Processes every collision that occurred.
   - Updates the entity’s `x` / `y` to the final resolved position.
3. If the entity is not in the world (or collision is disabled), it simply moves by velocity.

If no world exists at all, entities with velocity are still moved (no collision).

---

### Collision Response

For every collision the following happens:

1. **Callbacks**  
   `entity.events.onCollision(item, other, dt)` is called on both participants (if defined).

2. **Platform riding**  
   If a Dynamic body lands on a Kinematic body from above (`normal.y < -0.5`), it inherits the Kinematic body’s velocity and is marked grounded.

3. **Slide / Touch response**
   - Landing from above → set `grounded = true`
   - Hitting a ceiling → zero vertical velocity
   - Hitting a wall → zero horizontal velocity

4. **Bounce response**
   - Reflects the appropriate velocity component(s)
   - Also sets `grounded` when landing from above

5. **Friction**  
   After the response, if the collision type is not `"cross"` and both entities have physics, a friction damping factor is applied:

   ```
   combinedFriction = sqrt(frictionScaleA * frictionScaleB)
   damping = max(0, 1 - (worldfriction * combinedFriction * dt))
   velocity *= damping
   ```

---

### Grounded & Coyote Time

- `grounded` is reset to `false` at the start of movement.
- It is set back to `true` when a collision with a floor (`normal.y < -0.5`) occurs.
- If the entity was grounded last frame but is no longer grounded, a short timer (0.1 s) is started. This is intended to support coyote-time style gameplay (the timer handle is named `"coyoteTimer"`).

Note: Some calls to cancel the coyote timer use slightly inconsistent argument styles (`"coyoteTimer"` string vs the handle itself).

---

### Integration with Other Systems

- **Physics System** calculates velocity and force.
- **World System** applies that velocity and resolves collisions.
- **ECS** automatically adds/removes entities from the world on register/destroy.
- Collision callbacks live on the entity’s `events.onCollision`.

---