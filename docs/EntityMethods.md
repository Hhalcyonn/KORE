**Entity Methods**

Every entity created by `ECS.createentity` receives a set of helper methods from `src/EntityMethods.lua`. These methods are attached via the entity’s metatable, so you call them with colon syntax (`entity:method(...)`).

---

### Lifecycle

#### `entity:Destroy()`
Marks the entity as dead (`alive = false`) and cancels all of its timers.  
The entity will be fully removed on the next call to `ECS.removeDeadEntities()`.

---

### State

#### `entity:setState(newState, callback)`
Changes `entity.state` to `newState`.  
If the state is already the same, the call is ignored.  
If a `callback` function is provided, it is called with the entity before the state is changed.

---

### Position & Spatial Queries

#### `entity:setPosition(x, y)`
Sets `entity.x` and `entity.y` directly.

#### `entity:getCoordinates()`
Returns `entity.x, entity.y`.

#### `entity:getCenter(datatype)`
Returns a point depending on `datatype`:

| datatype     | Returns                                      |
|--------------|----------------------------------------------|
| `"Drawdata"` | Center of the drawdata box                   |
| `"Collider"` | Center of the collider box                   |
| anything else| Center of the drawdata box                   |

#### `entity:distanceToAxes(target, centertype)`
Returns the vector (`dx, dy`) from this entity to `target`.

- `target` can be another entity or a pair of numbers (`x, y`).
- `centertype` can be `"Drawdata"` or `"Collider"` (defaults to `"Drawdata"` when target is an entity).

#### `entity:distanceTo(target, y)`
Returns the Euclidean distance to `target`

#### `entity:angleTo(target, y)`
Returns the angle (in radians) from this entity’s collider center to the target (entity or `x, y`).

#### `entity:lookAt(target, y, centerType)`
Sets `entity.drawdata.r` so the entity faces the target.  
`centerType` defaults to `"Drawdata"`.

---

### Facing

#### `entity:flip(value)`
- With no argument: toggles `facing` between `1` and `-1`.
- With `1` or `-1`: sets `facing` to that value.

---

### Physics Helpers

#### `entity:applyForce(fx, fy)`
Adds force to a Dynamic body.

#### `entity:applyImpulse(ix, iy)`
Adds an instantaneous velocity change.  
If the entity has mass, the impulse is divided by mass.

#### `entity:clearForces()`
Resets force to `{x = 0, y = 0}` on a Dynamic body.

#### `entity:setVelocity(vx, vy)`
Sets velocity on Dynamic or Kinematic bodies.

#### `entity:getVelocities()`
Returns `vx, vy` if the entity has physics, otherwise nothing.

#### `entity:stop()`
Sets velocity (and force on Dynamic bodies) to zero.

#### `entity:setAnchored(bool)`
Sets the `anchored` flag (ignored on Static bodies).

#### `entity:isAnchored()`
Returns the current `anchored` value (or `nil` if no physics).

#### `entity:isGrounded()`
Returns `true`/`false` for Dynamic bodies, otherwise `nil`.

#### `entity:onGrounded(callback, dt)`
If the entity is Dynamic and currently grounded, calls `callback(self, dt)`.

#### `entity:followTo(target, speed, dt, centertype)`
Applies force so the entity moves toward `target` at the given speed.  
Uses the physics force system (works best with Dynamic bodies).  
If `dt ≤ 0`, velocity is set directly.

#### `entity:setBodytype(data)`
Completely replaces the physics table with a new body type.  
`data` must contain a `bodytype` field (`"Dynamic"`, `"Kinematic"`, or `"Static"`).  
Other fields are optional and use defaults when missing.

#### `entity:setPhysics(arg, arg2)`
Modifies individual physics properties. Supported keys:

| arg             | Expected type | Notes |
|-----------------|---------------|-------|
| `"gravityScale"`| number        | Dynamic only |
| `"dragScale"`   | number        | Dynamic only |
| `"frictionScale"`| number       | All body types |
| `"mass"`        | number        | Dynamic only |
| `"velocity"`    | `{x, y}`      | Dynamic / Kinematic |
| `"maxSpeed"`    | `{x, y}`      | Dynamic only |
| `"grounded"`    | boolean       | Dynamic only |
| `"anchored"`    | boolean       | Non-Static only |
| `"overSpeedMode"`| string       | Dynamic only |
| `"force"`       | `{x, y}`      | Dynamic only |

Invalid combinations log a warning.

---

### Health

#### `entity:heal(value)`
Adds `value` to `health.current` (if the entity has health).

#### `entity:damage(value)`
Subtracts `value` from `health.current`.

---

### Collider & Draw Data

#### `entity:setCollider(data)`
Updates any of the following fields if present in `data`:

- `collision`
- `collisionfilter`
- `width`
- `height`
- `offsetx`
- `offsety`

#### `entity:setDrawdata(data)`
Updates any of the following fields if present in `data`:

- `drawable`, `width`, `height`
- `r`, `sx`, `sy`, `ox`, `oy`, `kx`, `ky`
- `layer`

#### `entity:setLayer(layer)`
**Currently broken** in v3.15.  
The implementation uses the global name `entity` instead of `self` and performs a comparison (`==`) instead of an assignment. It has no effect.

---

### Animation

#### `entity:switchAnimation(animName, forceReset)`
Switches to the named animation.  
Resets the animation to frame 1 and resumes it.  
If the same animation is already playing and `forceReset` is false, the call is ignored.

#### `entity:pauseCurrentAnim()`
Pauses the currently playing animation.

#### `entity:resumeCurrentAnim()`
Resumes the currently playing animation.

#### `entity:isAnimPlaying(anim)`
Returns `true` if the named animation is currently active.

#### `entity:enteredFrame(frame, animationstate)`
Returns `true` only on the exact frame when the animation first reaches the given frame number (useful for one-shot effects).

#### `entity:addAnimCapability(animationpack)`
Removes any existing sprite and loads an animation pack (if the entity does not already have animations).

#### `entity:changeAnimPack(animationpack)`
Replaces the current animation pack.

#### `entity:removeAnimCapability()`
Removes animations and `animdata`.

---

### Sprite

#### `entity:addSpriteCapability(sprite)`
Removes any animations and sets a static sprite from `AssetsSystem.images`.

#### `entity:changeSprite(sprite)`
Changes the current static sprite.

#### `entity:removeSpriteCapability()`
Removes the static sprite.

---

### Identity & Tags

#### `entity:getIdentity(arg, tag)`
| arg     | Returns |
|---------|---------|
| `"name"`| name string |
| `"id"`  | numeric id |
| `"tag"` | whether the tag exists (`tag` is the tag name) |
| `"all"` | name, id, tags table |

#### `entity:hasTag(tag)`
Returns the value of `identity.tags[tag]` (truthy if the tag exists).

#### `entity:addTag(tag)` / `entity:removeTag(tag)`
Sets entity.tags[tag] to true or nil

---

### Timers

Timers are powered by HUMP’s timer library and are automatically cleaned up when the entity dies.

#### `entity:addTimer(delay, callback)`
Schedules a one-shot timer.  
`callback` receives the entity.  
Returns a handle that can be cancelled.

#### `entity:addRepeatingTimer(delay, callback)`
Schedules a repeating timer.  
If the callback returns `false`, the timer stops.  
Automatically cancels itself if the entity is no longer alive.

#### `entity:cancelTimer(handle)`
Cancels a specific timer.

#### `entity:cancelAllTimer()`
Cancels every timer belonging to the entity.  
(Note the singular name; `Destroy()` calls a non-existent `cancelAllTimers`.)

---

### Known Issues

- `getCenter("Drawdata")` returns entity.x, entity.y, which is the visual center for sprites because ox and oy default to half the drawdata dimensions. For debug rectangles, those coordinates remain the top-left corner. (I really dont know how to stabilize this tbh, just dont put custom ox, oy if you want it to be stable.)