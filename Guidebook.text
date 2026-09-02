# L2D-BootlegSet
## - L2D BootlegSet is a reuseable and flexible game framework I built ontop and for LOVE2D.
- L2D BootlegSet is fairly simple, it has a simple, easy-to-understand, hybrid entity component system that handles entity creation, input and update. So simple all you need to make an entity is just to type "ECS.register(ECS.createx())" and the ECS will handle unique naming, and organizing them into batches. Though it will just be boring.
- ECS does not handle drawing/BUMP collision. Drawing is handled by RenderComponentSystem, and BUMP collision is handled by WorldComponentSystem. Very simple Physics too.

### Entities are separated into 5 types.
- Structures: Static entity that doesn't move.
- Particles: Lightweight entity that doesn't collide.
- Objects: Entities that doesn't have health key.
- NPC: Basically object with health key.
- Player: NPC but with player input.
- I try to make it very flexible, and that's why I made it so that you can override anything in the entities.
- Entities have: Controller, Behavior, Beforeupdanim(For every entity type), Beforedying(only for NPC and Player), Collisionlogic(For everyone except particles), Keypressfunction(For player), Mousepressfunction(For player) and Customkeys(To store anything you want!).
- Entities have methods too! For an example Entity:moveTo(target) or Entity:faceTo(target).

### Every entity is organized into three batches.
- Entities: General list of entities in the game.
- Typebatch: List of entities by their Types
- Subtypebatch: List of entities by their name.

### Console
- L2D BootlegSet has a fairly simple console. Built in commands are: Kill (name, all, type x, subtype x), Spawn (create entity from prefabs.), and debug (That can set to be true or false.). You can add other commands inside Console:Init().

### Utilities
- L2D BootlegSet has some QOL utilities, for an example like assetsystem:loadpack(pack, packtype) that can automatically set up anim8 animation and mappacks from a data module. For anim8 animation just type ("yourmodulename", "anim8anim"), and for mappacks type ("yourmodulename", "map").
- In utils.lua theres function like distance() that calculate the distance between two things, lerp, clamp, splitname(for splitting entity unique name). Or just use HUMP's vector for math.

### Conclusion
- L2D BootlegSet is just a framework I made for my brain. Its messy, because im not aiming to make Unity V2. You can improve it if you want.
