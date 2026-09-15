**Render System**

The Render System is responsible for drawing all entities. It uses a multi-layer canvas approach, supports per-layer shaders, and provides built-in debug visualization.

It lives in `src/RenderSystem.lua` and is exposed as `KORE.RenderSystem`.

---

### Layers

Rendering is split into four fixed layers, drawn in this order:

1. `background`
2. `world`
3. `foreground`
4. `ui`

Each layer has its own canvas and an optional shader.

Entities choose their layer through `entity.drawdata.layer` (defaults to `"world"`).  
Unknown layer names fall back to the `world` layer and produce a warning.

---

### Initialization & Resizing

```lua
RenderSystem:init()
```

Creates canvases matching the current window size and sets their filter mode to `"nearest"`.

```lua
RenderSystem:resize(w, h)
```

Recreates all layer canvases at the new size.  
This is also called automatically inside `draw` if the window dimensions have changed.

---

### Drawing Entities

```lua
RenderSystem:draw(entities)
```

This is the main draw call (invoked by `KORE.draw`).

Process:

1. Ensures canvases match the current window size.
2. Clears every layer canvas to transparent.
3. Iterates all living entities (`alive ~= false`).
4. Draws each entity onto the canvas of its assigned layer.
5. Composites the four canvases to the screen in layer order, applying any assigned shaders.

#### How an individual entity is drawn

- If `drawdata.drawable == false` → skipped.
- If the entity has neither a sprite nor animations → a simple outline rectangle is drawn.
- If an animation is currently active (`animdata.current`) → the animation is drawn.
- Otherwise, if a static sprite exists → the sprite is drawn.

Drawing uses the entity’s `drawdata` for transformation:

| Field | Default | Purpose |
|-------|---------|---------|
| `r`   | `0`     | Rotation |
| `sx`  | `facing` or `1` | Scale X |
| `sy`  | `1`     | Scale Y |
| `ox`  | half width | Origin X |
| `oy`  | half height | Origin Y |
| `kx`  | `0`     | Shear X |
| `ky`  | `0`     | Shear Y |

The draw position comes from `entity:getCenter("Drawdata")`.

---

### Shaders

Shaders can be assigned per layer.

```lua
RenderSystem:setShader(layerName, shader)   -- returns true on success
RenderSystem:getShader(layerName)
RenderSystem:clearShader(layerName)
RenderSystem:clearAllShaders()
```

When a layer has a shader, it is applied while that layer’s canvas is drawn to the screen.

---

### Debug Drawing

Two debug modes are available.

#### In-world debug (`drawdebuginworld`)

Drawn while the camera is still attached (so it moves with the world).

For every living entity it draws:

- Red outline → collider box
- Blue outline → drawdata box
- White text → entity ID above the entity

#### On-screen debug (`drawdebugonscreen`)

Drawn after the camera is detached (screen-space).

Currently shows:

- Total entity count at position `(10, 10)`

---

### Custom Debug Hooks

You can inject your own debug drawing code:

```lua
RenderSystem.screendebug(function(entities)
    -- called from drawdebugonscreen
end)

RenderSystem.worlddebug(function(entities)
    -- called from drawdebuginworld
end)
```

**Note:** The `worlddebug` setter currently contains a typo (`RendderSystem` instead of `RenderSystem`) and will not work until fixed.

---

### Integration with the Main Loop

In `KORE.draw`:

1. Camera is attached (if present).
2. `RenderSystem:draw(entities)` is called.
3. If debug mode is enabled → `drawdebuginworld` is called.
4. Camera is detached.
5. `drawdebugonscreen` is called.
6. Console is drawn on top.

---