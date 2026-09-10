add shaders support for assetssystem

renew entity physics
renew physicssystem
make sure entity width and height call back work with animation.
accomodate every system with the new physics especially physicssystem

Phase 1: Foundation (Do this first)

Create a proper entity.physics table
Move all physics-related data into one place:
bodyType ("dynamic", "kinematic", "static")
velocity = {x = 0, y = 0}
forces = {x = 0, y = 0}
mass
gravityScale
drag (air)
friction (ground)
maxSpeed = {x = ..., y = ...}
grounded
anchored (optional temporary freeze)


Update entity creation
In ECS.createentity, detect if the entity should have physics and build the physics table cleanly.
Keep backward compatibility for a while if you want (velocityx, gravity, etc. can still work as fallbacks).

Clear separation of duties
PhysicsSystem → only calculates velocity (forces, gravity, drag, friction)
WorldSystem → only moves the entity using that velocity and resolves collisions
Never set entity.x / entity.y inside PhysicsSystem



Phase 2: Core Physics Loop

Force-based update in PhysicsSystem
Every frame:
Apply gravity (scaled by gravityScale)
Add any accumulated forces
Integrate into velocity (v = v + (forces / mass) * dt)
Apply drag or friction depending on grounded state
Clamp to maxSpeed
Clear forces after use


Add helper methods on entities
entity:applyForce(fx, fy)
entity:applyImpulse(ix, iy)
entity:setVelocity(vx, vy) (sometimes useful)
entity:isGrounded()

Improve grounded detection
In WorldSystem, after world:move(), check collision normals.
Set physics.grounded = true only when there’s a collision with normal pointing upward (e.g. normal.y < -0.5).



Phase 3: Body Types

Implement bodyType behavior
static → skip all physics, never move
kinematic → can be moved by code, but ignores forces/gravity
dynamic → full physics

Handle anchored
If anchored == true, treat it like temporary static (ignore forces + controller)



Phase 4: Quality of Life (makes it feel good)

Separate air drag vs ground friction
Terminal velocity (max fall speed)
Optional gravity per entity (already covered by gravityScale)
Basic material support (different friction when colliding with certain objects)


Phase 5: Future-proofing (later)

Moving platforms (kinematic bodies that carry dynamic bodies)
One-way platforms
Slopes
Coyote time + jump buffering (very important for platformers)
Sub-stepping or continuous collision if you need high speeds


Suggested Order of Work

Redesign entity.physics table
Update createentity
Rewrite PhysicsSystem.update (force-based)
Update WorldSystem to only read velocity and handle movement + grounded
Add applyForce / applyImpulse
Test with a player controller
Add bodyType logic
Polish friction/drag/terminal velocity