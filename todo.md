# ECS v2 migration TODO

## Blocking compatibility work

- [/] Replace old constructor calls or add wrappers for `createstructure`, `createplayer`, `createnpc`, `createobject`, and `createparticle`.
	Problem: `init.lua` still calls them at lines 124-148; `Prefabs.lua` calls them at lines 9, 49, and 60.
- [ID-keyed] Decide whether `ECS.entities` stays ID-keyed or becomes an array/dual index.
	Problem: V2 stores entities by ID at `src/EntityComponentSystemv2.lua:21`, but `init.lua` iterates with `ipairs` at lines 77, 98, and 106.
- [/] Replace `typebatch` and `subtypebatch` consumers with identity/type queries, or restore compatibility indexes.
	Problem: `Console.lua` reads `context.subtypebatch` at line 86; `init.lua` passes both batches at lines 47-48.
- [/] Preserve or migrate entity type values (`player`, `npc`, `object`, `particle`, `structure`).
	Problem: `RenderSystem.lua` checks `entity.type` at lines 55 and 78; `Console.lua` checks it at lines 43 and 57.
- [/] Preserve old asset input names or update all callers.
	Problem: old code uses `imagesprite` and `spritepack`; V2 only reads `sprite` and `animationpack` at lines 174-184.

## V2 correctness fixes

- [/] Fix the death timer field and callback condition.
	Problem: V2 creates `health.dyingduration` at line 126, reads `health.deathduration` at line 288, and checks `entity.health.dying` only after scheduling; keep one field consistently.
- [/] Add lifetime countdown and expiration.
	Problem: V2 stores `entity.lifetime` at line 106 but never decrements it in `ECS.update`.
- [/] Use the same drag field everywhere.
	Problem: V2 creates `dragval` at line 115, while existing movement code expects `appliedDragval` in `src/EntityMethods.lua:10` and old prefabs configure it in `src/Prefabs.lua:17`.
- [/] Confirm collider and draw-data defaults use nested `data.collider` and `data.drawdata` fields.
	Problem: draw dimensions read `data.spritewidth` and `data.spriteheight` at lines 226-229 instead of `data.drawdata.*`.
- [/] Remove the unused `vector` import, or use it in the new implementation.
	Problem: `src/EntityComponentSystemv2.lua:2` imports it but no code references it.

## Entity API validation

- [/] Verify entity methods are attached to created entities.
	Problem: V2 correctly uses `Entity` as the metatable at line 98, but confirm `EntityMethods.lua` methods work with the new `identity` shape; `getIdentity` currently references `self.Identity` instead of `self.identity` at `src/EntityMethods.lua:68-75`.
- [/] Add `onCollision`, `collisionlogic`, `beforedying`, and input callback compatibility.
	Problem: V2 only stores `onCollision` at line 165 and does not store the old `collisionlogic`/`beforedying` fields used by existing systems.
- [KORE.spawnEntity(data)] Decide whether `createentity` auto-registers entities.
	Problem: V2 creates an ID at line 103 but does not add the entity to `ECS.entities` until callers explicitly invoke `ECS.register`.

## Verification

- [ ] Update `src/init.lua` to require V2 only after the compatibility work is complete.
- [ ] Spawn one entity of each former type and verify rendering, input, physics, collision, lifetime, death, and removal.
- [ ] Run a Lua syntax check on `src/EntityComponentSystemv2.lua` and a smoke test through `KORE.load`, `KORE.update`, and `KORE.draw`.
