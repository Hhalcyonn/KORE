# Changelog

## Snapshot 2.0

### Added

* Added `KORE` public API facade for accessing framework systems and libraries.
* Added centralized framework update and draw handling.
* Added centralized LÖVE input event forwarding.
* Added `KORE.Log` logging system with debug, info, warning, error, and failure levels.
* Added custom console command registration through `KORE.AddCommand`.
* Added protected command execution.
* Added camera management API.
* Added shader management API.
* Added per-layer shader support.
* Added debug controls and debug target functionality.
* Added runtime window resize handling.
* Added entity timers using HUMP Timer.
* Added entity lifecycle cleanup for timers and callbacks.
* Added entity identity system containing:

  * Unique name
  * Unique ID
  * Custom tags
* Added tag-based entity identification and management.
* Added identity helper methods.
* Added entity state management.
* Added spatial helper methods:

  * Position
  * Center
  * Distance
  * Angle
  * Look-at
* Added entity facing and flipping support.
* Added runtime collider manipulation.
* Added runtime draw-data manipulation.
* Added render layer management.
* Added health and damage helpers.
* Added animation control and animation state tracking.
* Added animation frame-entry detection.
* Added animation capability management.
* Added sprite capability management.
* Added runtime sprite replacement.
* Added runtime animation-pack replacement.
* Added physics body types:

  * Dynamic
  * Kinematic
  * Static
* Added force and impulse physics.
* Added mass, gravity scale, drag scale, friction scale, and maximum-speed controls.
* Added anchored physics state.
* Added grounded state and grounded callbacks.
* Added runtime physics body-type switching.
* Added physics configuration through `setPhysics`.
* Added world-level gravity, drag, friction, and physics controls.
* Added physics velocity and force management methods.
* Added world packs through `AssetsSystem`.
* Added shader loading and storage to `AssetsSystem`.
* Added animation and sprite pack loading.
* Added asset reload functionality.
* Added asset aliases for easier access.
* Added dedicated `Commands` module for console commands.
* Added dedicated `Log` module for framework logging.

### Changed

* Reworked the ECS architecture.
* Entities are now stored by unique ID rather than relying on array indexing.
* Replaced the old type/subtype entity categorization system with flexible tags.
* Reworked entity creation around `ECS.createentity`.
* Reworked entity identity into a dedicated identity structure.
* Reorganized entity callbacks into `entity.events`.
* Reorganized animation state around `animdata.current`.
* Added per-animation previous-frame tracking.
* Reworked physics from flat entity properties into a structured physics system.
* Reworked collision handling around the new physics body system.
* Standardized internal module imports around the `KORE.` package prefix.
* Reworked the public API so framework functionality can be accessed through `KORE`.
* Expanded `EntityMethods` substantially.
* Expanded `WorldSystem` to work with the new physics architecture.
* Expanded `RenderSystem` with layers, shaders, and additional debug functionality.
* Expanded `AssetsSystem` with more asset types and pack loading.
* Split console command functionality out of the main console implementation.
* Added consistent logging throughout framework systems.
* Reorganized the asset directory structure.
* Updated documentation to cover the major framework systems and APIs.

### Removed

* Removed the old ECS type/subtype batching system.
* Removed the previous entity registration architecture.
* Removed the old flat physics-property architecture.
* Removed the previous ECS implementation in favor of the rewritten ECS.
* Removed several rigid framework assumptions in favor of developer-controlled entity data and capabilities.

### Documentation

Added documentation for:

* `AssetsSystem`
* `EntityComponentSystem`
* `EntityMethods`
* `PhysicsSystem`
* `RenderSystem`
* `WorldSystem`
* Console & Commands
* Logging

---

## Snapshot 1.0 → Snapshot 2.0

KORE has been substantially reworked from the original Snapshot 1.0 architecture.

The ECS was rewritten, entity identity was redesigned around IDs, names, and tags, physics was rebuilt around multiple body types and forces, and the framework gained a centralized public API.

The framework also gained expanded asset management, animation and sprite capabilities, entity timers, health utilities, camera and shader controls, debugging tools, console commands, logging, and significantly expanded `EntityMethods`.

The overall architecture is now focused on giving the developer direct control over entities and framework systems without requiring a fixed game architecture.