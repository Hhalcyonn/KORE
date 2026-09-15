**AssetsSystem**

The AssetsSystem is responsible for loading, storing, and providing access to game assets (images, sounds, fonts, and shaders), as well as specialized packs for animations and world data.

It is exposed both directly as `KORE.AssetsSystem` and through convenience aliases:

- `KORE.images` → `AssetsSystem.images`
- `KORE.sounds` → `AssetsSystem.sounds`
- `KORE.fonts` → `AssetsSystem.fonts`
- `KORE.shaders` → `AssetsSystem.shaders`

---

### Initialization

```lua
AssetsSystem.init(context)
```

or via the main entry point:

```lua
KORE.initAssetsPath(context)
```

`context` is expected to be a table that can contain the following optional keys:

| Key                | Default value          | Purpose                          |
|--------------------|------------------------|----------------------------------|
| `spritefolder`     | `"assets/sprites"`     | Folder containing image files    |
| `spritepacksfolder`| `"assets/spritepacks"` | Folder containing sprite pack Lua files |
| `worldpackfolder`  | `"assets/world"`       | Folder containing world pack Lua files |
| `soundfolder`      | `"assets/sounds"`      | Folder containing sound files    |
| `fontfolder`       | `"assets/fonts"`       | Folder containing font files     |
| `shaderfolder`     | `"assets/shaders"`     | Folder containing shader files   |

If `context` is `nil`, the defaults above are used and an info message is logged.

Calling `init` only sets the folder paths. It does **not** load any assets.

---

### Loading Individual Asset Types

These functions clear the corresponding table and then load every file found in the configured folder.

#### Images
```lua
AssetsSystem.loadimages()
```
- Scans `spritefolder`
- Creates `love.graphics.newImage` for every file
- Stores each image under **two** keys:
  - lowercase filename (`"player.png"`)
  - original filename (`"Player.PNG"`)
- Returns the `images` table
- Logs how many images were loaded

#### Sounds
```lua
AssetsSystem.loadsounds()
```
- Scans `soundfolder`
- Creates `love.audio.newSource` for every file
- Stores under both lowercase and original filename
- Returns the `sounds` table

#### Fonts
```lua
AssetsSystem.loadfonts()
```
- Scans `fontfolder`
- Creates `love.graphics.newFont` for every file
- Stores under both lowercase and original filename
- Returns the `fonts` table

#### Shaders
```lua
AssetsSystem.loadshaders()
```
- Scans `shaderfolder`
- Creates `love.graphics.newShader` for every file
- Stores under both lowercase and original filename
- Returns the `shaders` table

All four loaders only process files (they ignore subdirectories).

---

### Reloading Assets

```lua
AssetsSystem.reloadassets(assettype)
```

- If `assettype` is `nil` (or omitted), reloads **all** asset types (images, sounds, fonts, shaders).
- If a string is passed (`"images"`, `"sounds"`, `"fonts"`, or `"shaders"`), only that type is reloaded.
- Any other value logs a warning.
- Always logs start and end markers (`== reloading assets ==` / `== reloaded assets ==`).

This is the function called by `KORE.load()`.

---

### Packs

#### Animation / Sprite Packs

```lua
local pack = AssetsSystem.loadpack(packName, "anim8anim")
```

- `packName` is the name of a Lua file (without `.lua`) inside `spritepacksfolder`.
- The file is required and is expected to return a table of named entries.
- Each entry should contain:

```lua
{
    type        = "animation" or "image",
    image       = "filename.png",   -- key that exists in AssetsSystem.images
    -- for type == "animation":
    frameWidth  = number,
    frameHeight = number,
    frames      = string or table,  -- anim8 frames argument
    row         = number,
    speed       = number            -- anim8 duration
}
```

Behavior:
1. Ensures images are loaded (calls `loadimages()` if the images table is empty).
2. Looks up the image using both lowercase and original key.
3. If the image is missing, calls `log.fail` (which raises an error).
4. For `"animation"` entries, creates an `anim8` grid + animation.
5. Returns a table of the form:

```lua
{
    [name] = {
        type = "animation" | "image",
        image = Image,
        previousframe = 0,          -- only for animations
        animation = anim8.Animation -- only for animations
    },
    ...
}
```

This returned table is what gets assigned to `entity.animations` when you spawn an entity with an `animationpack` field.

#### World Packs

```lua
local worldData = AssetsSystem.loadpack(packName, "world")
```

- Requires a Lua file from `worldpackfolder`.
- Simply returns whatever the file returns (normally a list/table of entity data tables).
- Used by `KORE.loadworld()` and `WorldSystem.initworld()`.

Any other `packtype` causes `log.fail`.

---

### Storage Tables

| Table                    | Contents                          | Access                  |
|--------------------------|-----------------------------------|-------------------------|
| `AssetsSystem.images`    | Loaded `Image` objects            | `KORE.images`           |
| `AssetsSystem.sounds`    | Loaded `Source` objects           | `KORE.sounds`           |
| `AssetsSystem.fonts`     | Loaded `Font` objects             | `KORE.fonts`            |
| `AssetsSystem.shaders`   | Loaded `Shader` objects           | `KORE.shaders`  |

All tables are cleared and rebuilt on each load/reload of that asset type.

---

### Typical Usage Flow

```lua
-- 1. Set folders (optional)
KORE.initAssetsPath({
    spritefolder     = "assets/sprites",
    spritepacksfolder = "assets/spritepacks",
    -- ...
})

-- 2. Load everything
KORE.load()          -- internally calls AssetsSystem.reloadassets()

-- 3. Use assets
local img = KORE.images["player.png"]
local snd = KORE.sounds["jump.ogg"]

-- 4. Load a sprite pack for an entity
local anims = KORE.AssetsSystem.loadpack("player", "anim8anim")
```

---