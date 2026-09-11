local ConsoleSystem = {
    open = false,
    input = {text = ""},
    output = {},
    commands = {}
}
local BASE = (...) .. "."
local Commands = require(BASE .. "src.Commands")

function ConsoleSystem:addCommand(name, callback)
    self.commands[name] = callback
end

function ConsoleSystem:init(context)
    self.context = context

    Commands.register(self)
end

local function splitCommand(text)
    local words = {}

    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    return words
end

function ConsoleSystem:execute(text)
    local words = {}
    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    local commandName = table.remove(words, 1)
    if not commandName then return end

    local command = self.commands[commandName]
    if not command then
        return "Unknown command: " .. commandName
    end

    local success, result = pcall(command, words)
    if not success then
        return "Error: " .. tostring(result)
    end

    return result
end

function ConsoleSystem:update()
    if not self.open then
        return
    end

    love.keyboard.setTextInput(true)
end

function ConsoleSystem:draw()
    if not self.open then
        return
    end

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 0, 0, 540, 140)

    love.graphics.setColor(1, 1, 1)

    local y = 50
    for index = math.max(1, #self.output - 3), #self.output do
        love.graphics.print(self.output[index], 0, y)
        y = y + 20
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", 0, 0, 500, 28)
    love.graphics.print(self.input.text, 8, 5)
end

function ConsoleSystem:keypressed(key)
    if key == "`" then
        self.open = not self.open
        love.keyboard.setTextInput(self.open)
        if not self.open then
            self.input.text = ""
        end
        return true
    end

    if not self.open then
        return false
    end

    if key == "backspace" then
        self.input.text = self.input.text:sub(1, -2)
        return true
    end

    if key == "return" then
        local result = self:execute(self.input.text)

        if result then
            table.insert(self.output, result)
        end

        self.input.text = ""
        return true
    end

    if key == "escape" then
        self.open = false
        love.keyboard.setTextInput(false)
        return true
    end

    return true
end

function ConsoleSystem:textinput(text)
    if self.open then
        self.input.text = self.input.text .. text
    end
end

function ConsoleSystem:textedited(text, start, length)
    -- Not needed for the console input; textinput handles plain typing.
end

return ConsoleSystem