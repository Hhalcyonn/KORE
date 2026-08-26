local suit = require("libs/suit")
local factory = require("src/Prefabs")

local ConsoleSystem = {
    open = false,
    input = {text = ""},
    output = {},
    commands = {}
}

function ConsoleSystem:init(context)
    self.context = context

    self.commands.spawn = function(arguments)
        local entityName = arguments[1]
        local posx = tonumber(arguments[2]) or context.player.x + 500
        local posy = tonumber(arguments[3]) or context.player.y + 200
        local chartype = arguments[4] or "npc"
        if posx ~= nil and posy ~= nil then
            if entityName == "smiler" then
                local entity = factory.createSmiler(posx, posy, context.player)

                table.insert(context.entities, entity)
                context.WorldSystem.addtoworld({entity})

                return "Spawned smiler"
            elseif entityName == "stickmanwhite" or entityName == "white" then
                local entity = factory.createCharacter("white", posx, posy, chartype)
                if not entity then
                    return "Unknown character type: " .. tostring(chartype)
                end

                table.insert(context.entities, entity)
                context.WorldSystem.addtoworld({entity})

                return "Spawned " .. chartype .. " white"
            else
                return "Unknown entity: " .. tostring(entityName)
            end
        else
            return "No PosX and PosY argument."
        end
    end
    self.commands.kill = function(arguments)
        local target = arguments[1]

        if target == "all" then
            local entityCount = 0
            for _, entity in ipairs(context.entities) do
                if entity ~= context.player and entity.entitytype ~= "structure" then
                    entity.alive = false
                    entityCount = entityCount + 1
                end
            end
            return "Killed " .. entityCount .. " entities."
        end

        local entityIndex = tonumber(target)
        local entity = entityIndex and context.entities[entityIndex]
        if not entity then
            return "Unknown entity index: " .. tostring(target)
        end

        if entity == context.player  then
            return "Cannot kill the player."
        end

        entity.alive = false
        return "Killed entity " .. tostring(entityIndex) .. "."
    end
end

local function splitCommand(text)
    local words = {}

    for word in text:gmatch("%S+") do
        table.insert(words, word)
    end

    return words
end

function ConsoleSystem:execute(text)
    local words = splitCommand(text)
    local commandName = table.remove(words, 1)

    if not commandName or commandName == "" then
        return
    end

    local command = self.commands[commandName]

    if not command then
        return "Unknown command: " .. commandName
    end

    return command(words)
end

function ConsoleSystem:update()
    if not self.open then
        return
    end

    suit.layout:reset(20, 20)

    local state = suit.Input(
        self.input,
        {id = "console_input"},
        suit.layout:row(500, 32)
    )

    if state.submitted then
        local result = self:execute(self.input.text)

        if result then
            table.insert(self.output, result)
        end

        self.input.text = ""
    end
end

function ConsoleSystem:draw()
    if not self.open then
        return
    end

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.rectangle("fill", 10, 10, 540, 140)

    love.graphics.setColor(1, 1, 1)

    local y = 50
    for index = math.max(1, #self.output - 3), #self.output do
        love.graphics.print(self.output[index], 20, y)
        y = y + 20
    end

    suit.draw()
end

function ConsoleSystem:keypressed(key)
    if key == "`" then
        self.open = not self.open
        return true
    end

    if self.open then
        suit.keypressed(key)
        return true
    end

    return false
end

function ConsoleSystem:textinput(text)
    if self.open then
        suit.textinput(text)
    end
end

function ConsoleSystem:textedited(text, start, length)
    if self.open then
        suit.textedited(text, start, length)
    end
end

return ConsoleSystem