-- src/Log.lua
local Log = {
    history = {},
    maxHistory = 100,
    enablePrint = true,
    enableFile = true,
    filename = "log.txt"
}

local levels = {
    DEBUG = 1,
    INFO  = 2,
    WARN  = 3,
    ERROR = 4,
    FATAL = 5
}

local function write(level, msg)
    local time = os.date("%H:%M:%S")
    local line = string.format("[%s] [%s] %s", time, level, tostring(msg))

    table.insert(Log.history, line)
    if #Log.history > Log.maxHistory then
        table.remove(Log.history, 1)
    end

    if Log.enablePrint then
        print(line)
    end

    if Log.enableFile then
        love.filesystem.append(Log.filename, line .. "\n")
    end
end

function Log.debug(msg) write("DEBUG", msg) end
function Log.info(msg)  write("INFO",  msg) end
function Log.warn(msg)  write("WARN",  msg) end
function Log.error(msg) write("ERROR", msg) end

function Log.fail(msg, level)
    write("FATAL", msg)
    error("[KORE] " .. tostring(msg), (level or 1) + 1)
end

return Log