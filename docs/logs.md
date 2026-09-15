**Log**

The Log module provides a simple logging system used throughout KORE. It writes timestamped messages to both the console and a file, and keeps a short in-memory history.

It lives in `src/Log.lua` and is exposed as `KORE.Log`.  
Convenience wrappers also exist on the main KORE table:

```lua
KORE.logdebug(msg)
KORE.loginfo(msg)
KORE.logwarn(msg)
KORE.logerror(msg)
KORE.logfail(msg, level)
```

---

### Configuration

| Field          | Default            | Description |
|----------------|--------------------|-------------|
| `history`      | `{}`               | In-memory list of recent log lines |
| `maxHistory`   | `100`              | Maximum number of lines kept in `history` |
| `enablePrint`  | `true`             | Whether messages are printed to the console |
| `enableFile`   | `true`             | Whether messages are appended to a file |
| `filename`     | `"KORE/log.txt"`   | Path used for file logging (relative to the save directory) |

These fields can be modified at runtime if needed.

---

### Log Levels

The module defines five levels:

- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`
- `FATAL`

Every message is formatted as:

```
[HH:MM:SS] [LEVEL] message
```

---

### Public Functions

#### `Log.debug(msg)`
Writes a `DEBUG` message.

#### `Log.info(msg)`
Writes an `INFO` message.

#### `Log.warn(msg)`
Writes a `WARN` message.

#### `Log.error(msg)`
Writes an `ERROR` message.

#### `Log.fail(msg, level)`
Writes a `FATAL` message and then raises a Lua error.

- `msg` — the error message
- `level` (optional) — error level passed to Lua’s `error()` function (defaults to `1`)

The raised error is prefixed with `"[KORE] "`.

This is the function used by systems (for example `AssetsSystem`) when a critical failure occurs (missing required image, unknown pack type, etc.).

---

### Behavior of `write`

All logging functions go through an internal `write(level, msg)` function that:

1. Formats the line with the current time and level.
2. Appends it to `Log.history`.
3. Trims the history if it exceeds `maxHistory` (oldest entry is removed).
4. Prints the line if `enablePrint` is `true`.
5. Appends the line to the log file if `enableFile` is `true` (using `love.filesystem.append`).

---

### Notes

- File logging uses LÖVE’s save directory. The file is created automatically on the first write.
- `Log.fail` is the only function that stops execution (by calling `error`).
- The history is a simple array; it is not exposed through any helper methods (you can read `KORE.Log.history` directly if needed).