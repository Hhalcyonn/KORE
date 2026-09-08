local RenderSystem = {}
local drawbatchbackground = {}
local drawbatchworld = {}
local drawbatchforeground = {}

local function drawsprite(sprite, x, y, data, facing)
    if not sprite then
        return
    end

    local r = data.r or 0
    local sx = facing or data.sx or 1
    local sy = data.sy or 1
    local ox = data.ox or 0
    local oy = data.oy or 0

    if sprite.type == "animation" then
        sprite.animation:draw(
            sprite.image,
            x + data.width / 2,
            y + data.height / 2,
            r,
            sx,
            sy,
            data.width / 2,
            data.height / 2
        )

    elseif sprite.type == "image" then
        love.graphics.draw(
            sprite.image,
            x + data.width / 2,
            y + data.height / 2,
            r,
            sx,
            sy,
            data.width / 2,
            data.height / 2
        )
    end
end

function RenderSystem:draw(entitylist)
    local layers = {
        background = {},
        world = {},
        foreground = {},
        ui = {}
    }

    -- Sort entities into temporary layer lists
    for _, entity in pairs(entitylist) do
        if entity.alive ~= false then
            local layer = (entity.drawdata and entity.drawdata.layer) or "world"
            if layers[layer] then
                table.insert(layers[layer], entity)
            else
                table.insert(layers.world, entity) -- fallback
            end
        end
    end

    local function drawEntity(entity)
        if not entity.sprite and not entity.animations then
            love.graphics.rectangle("line", entity.x, entity.y, entity.drawdata.width, entity.drawdata.height)
            return
        end

        if entity.sprite then
            drawsprite(entity.sprite, entity.x, entity.y, entity.drawdata, entity.facing)
        end

        if entity.animations and entity.state then
            local current = entity.animations[entity.state]
            if current then
                drawsprite(current, entity.x, entity.y, entity.drawdata, entity.facing)
            end
        elseif entity.animation and not entity.state then
            error("At least one " .. entity.type .. " has animation but no state")
        end
    end

    -- Draw in correct order
    for _, entity in pairs(layers.background) do
        drawEntity(entity)
    end
    for _, entity in pairs(layers.world) do
        drawEntity(entity)
    end
    for _, entity in pairs(layers.foreground) do
        drawEntity(entity)
    end
    for _, entity in pairs(layers.ui) do
        drawEntity(entity)
    end
end

local focusent

function RenderSystem:focusdebugon(arg, arg2)
    local ecs = require("src/EntityComponentSystem")
    if type(arg) == "string" and arg == "name" then
        for _, entity in pairs(ecs.entities) do
            local name = entity:getIdentity("name")
            if name == arg2 then
                focusent = entity
                return true
            end
        end
    end
    if type(arg) == "number" then
        focusent = ecs.entities[arg]
    end
    if type(arg) == "string" and arg == "tag" then
        for _, entity in pairs(ecs.entities) do
            if entity:getIdentity("tag", arg2) then
                focusent = entity
                return true
            end
        end
    end
end

function RenderSystem:drawdebuginworld(entitylist)
    for _, entity in pairs(entitylist) do
        if entity.collider then
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle(
                "line",
                entity.x + entity.collider.offsetx,
                entity.y + entity.collider.offsety,
                entity.collider.width,
                entity.collider.height
            )
            love.graphics.setColor(1, 1, 1)
        else
            love.graphics.setColor(1, 0, 0)
            love.graphics.rectangle(
                "line",
                entity.x,
                entity.y,
                entity.drawdata.width,
                entity.drawdata.height
            )
            love.graphics.setColor(1, 1, 1)
        end
        local spriteWidth = entity.drawdata and entity.drawdata.width or 0
        local debugX = entity.x +spriteWidth + 12
        local debugY = entity.y
        local function printDebug(text)
            love.graphics.print(text, debugX, debugY)
            debugY = debugY + 20
        end

        local identity = entity.identity or {}
        printDebug(entity .. " State: " .. tostring(entity.state))
        printDebug(entity .. " Facing: " .. tostring(entity.facing))
        printDebug(entity .. " ID: " .. tostring(identity.id))
        printDebug(entity .. " Name: " .. tostring(identity.name))
        printDebug(entity .. " Tags: " .. table.concat(identity.tags or {}, ", "))
        printDebug(entity .. " X, Y: " .. entity.x .. ", " .. entity.y)

        love.graphics.setColor(1, 1, 1)
        if entity.velocityx ~= nil and entity.velocityy ~= nil then
            printDebug(entity .. " VelocityX: " .. math.floor(entity.velocityx))
            printDebug(entity .. " VelocityY: " .. math.floor(entity.velocityy))
        end
        printDebug(entity .. " Grounded: " .. tostring(entity.grounded == true))
    end
end

function RenderSystem:drawdebugonscreen(entitylist)
    if focusent then
        love.graphics.setColor(1, 1, 1)
        local debugY = 280
        local function printDebug(text)
            love.graphics.print(text, 0, debugY)
            debugY = debugY + 20
        end
        if focusent.velocityx ~= nil and focusent.velocityy ~= nil then
            printDebug(focusent .. " VelocityX: " .. math.floor(focusent.velocityx))
            printDebug(focusent .. " VelocityY: " .. math.floor(focusent.velocityy))
        end
        printDebug(focusent .. " State: " .. tostring(focusent.state))
        printDebug(focusent .. " Facing: " .. tostring(focusent.facing))
        printDebug(focusent .. " Grounded: " .. tostring(focusent.grounded == true))
    else
        love.graphics.print("No entity to focus debug.", 0, 280)
    end
    local count = 0
    for _, entity in pairs(entitylist) do
        count = count + 1
    end
    love.graphics.print("Entity count: " .. count, 0, 380)
end

return RenderSystem

-- ANIMATED SPRITE MUST HAVE STATE! im too lazy to fix it