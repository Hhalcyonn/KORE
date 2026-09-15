**Console & Commands**

KORE includes a simple in-game developer console for runtime debugging and command execution. It is implemented across two files:

- `src/Console.lua` — the console UI and input handling
- `src/Commands.lua` — registration of built-in commands

The console is automatically initialized when you call `KORE.load()`.

---

### Overview

The console can be toggled open/closed at runtime. When open it captures keyboard input, displays a small overlay, and allows you to type and execute commands.

It is designed as a lightweight development tool rather than a full scripting environment.

---

### Opening / Closing the Console


| Key       | Action                          |
|-----------|---------------------------------|
| `` ` ``   | Toggle console open / closed    |
| `Escape`  | Close the console               |
(`` ` `` is just the default, you can change the ConsoleKey by changing init.lua config)
When the console is open:
- Text input is enabled (`love.keyboard.setTextInput(true)`)
- Most other key presses are consumed by the console
- The input buffer is cleared when the console is closed

---

### Visual Appearance

When open, the console draws:

- A semi-transparent black rectangle (`0, 0, 0, 0.8`) of size **540 × 140** pixels in the top-left corner
- The last **4** lines of output (scrolling upward as new results appear)
- A text input field at the top with a white border

The console is drawn **after** the main game world (it is not affected by the camera).

---

### Adding Custom Commands

You can register your own commands at any time:

```lua
KORE.AddCommand("mycommand", function(arguments)
    -- arguments is a table of strings (words after the command name)
    return "Result message shown in the console"
end)
```

or directly:

```lua
KORE.ConsoleSystem:addCommand("mycommand", callback)
```

The callback receives a single argument: a table of the remaining words after the command name (split on whitespace).

If the callback returns a string (or any value), that value is converted to a string and added to the console output.  
If the callback raises an error, the console shows `"Error: ..."` instead.

---

### Executing Commands

Commands are executed when you press `Return` while the console is open.

The input string is split on whitespace. The first word is treated as the command name; the rest become the `arguments` table passed to the callback.

Example:

```
kill tag enemy
```

becomes:

```lua
commandName = "kill"
arguments   = { "tag", "enemy" }
```

---

### Built-in Commands

These are registered automatically during `KORE.load()` via `Commands.register()`.

#### `debug`

```
debug true
debug false
```

Enables or disables the global debug rendering flag (collider outlines, draw bounds, entity IDs, etc.).

Returns a confirmation message.

#### `kill`

Kills (sets `alive = false`) one or more entities.

Supported forms:

| Command                | Effect                                      |
|------------------------|---------------------------------------------|
| `kill all`             | Marks every entity as dead                  |
| `kill id <number>`     | Kills the entity with the given identity ID |
| `kill tag <tagname>`   | Kills every entity that has the given tag   |
| `kill name <name>`     | Kills the first entity with the matching name |

Returns a short status message (number of entities killed, or an error if the target was not found).

#### `spawn`

```
spawn <name> [x] [y] [amount]
```

**Currently incomplete.**  
The command parses the arguments but does not actually spawn any entities or return a result. I plan to make it spawn things from prefabs in next snapshot. Though you can just make it functionable if you want.

---

### Context Passed to Commands

When the console is initialized, it receives a context table containing:

```lua
{
    entities    = ECS.entities,      -- the live entity table
    WorldSystem = WorldSystem,       -- reference to the world system
    setDebug    = function(value)    -- used by the "debug" command
        debug = value
    end
}
```

Built-in commands that need access to entities or the debug flag use this context.

---

### Integration with the Game Loop

The main `KORE` module wires the console into LÖVE’s callbacks:

```lua
function KORE.keypressed(key)
    ConsoleSystem:keypressed(key)
    -- then forwards to entities...
end

function KORE.textinput(text)
    ConsoleSystem:textinput(text)
end

function KORE.textedited(text, start, length)
    ConsoleSystem:textedited(text, start, length)
end
```

and draws it every frame:

```lua
function KORE.draw()
    -- ... world drawing ...
    ConsoleSystem:draw()
end
```

`ConsoleSystem:update()` is also called every frame (it only enables text input when the console is open).

---