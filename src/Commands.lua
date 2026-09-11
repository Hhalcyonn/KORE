local Commands = {}
local log = require(BASE .. "src.log")

function ConsoleSystem:addCommand(name, callback)
    self.commands[name] = callback
end

function Commands.register(console)
    local context = console.context

    console:addCommand("spawn", function(arguments)
        local entityName = arguments[1]
        local posx = tonumber(arguments[2]) or context.player.x + math.random(-1000, 1000)
        local posy = tonumber(arguments[3]) or context.player.y + math.random(-1000, 1000)
        local amount = tonumber(arguments[4]) or 1
    end)

    console:addCommand("kill", function(arguments)
        local target = arguments[1]
        local entity

        if target == "all" then
            local entityCount = 0
            for _, entity in pairs(context.entities) do
                entity.alive = false
                entityCount = entityCount + 1
            end
            return "Killed " .. entityCount .. " entities."
        end
        
        if target == "id" then
            local id = tonumber(arguments[2])
            if not id then
                return "Please specify an entity id to kill."
            end
            if context.entities[id] then
                context.entities[id].alive = false
            end
            return "Killed entity " .. id .. "."
        end
        if target == "tag" then
            local tag = arguments[2]
            if not tag then
                return "Please specify a tag to kill."
            end
            local entityCount = 0
            for _, entity in pairs(context.entities) do
                if entity.identity.tags[tag] then
                    entity.alive = false
                    entityCount = entityCount + 1
                end
            end
           return "Killed " .. entityCount .. " entities with tag: " .. tag
        end
        if target == "name" then
            local name = arguments[2]
            for _, ent in pairs(context.entities) do
                if ent.identity.name == name then
                    entity = ent
                    break
                end
            end
        end
        if not entity then
            return "Unknown entity name: " .. name
        end
        entity.alive = false
        return "Killed entity " .. entity.identity.name .. "."
    end)
    console:addCommand("debug", function(arguments)
        local value = arguments[1]
        if value == "true" or value == "false" then
            local enabled = value == "true"
            context.setDebug(enabled)
            return "debug is: " .. tostring(enabled)
        end
        return tostring(value) .. " isn't a valid argument. Use true or false."
    end)
end

return Commands