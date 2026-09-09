-- src/RenderSystem.lua

local RenderSystem = {}

-- Layer configuration
local layerOrder = { "background", "world", "foreground", "ui" }

local layers = {
    background = { canvas = nil, shader = nil },
    world      = { canvas = nil, shader = nil },
    foreground = { canvas = nil, shader = nil },
    ui         = { canvas = nil, shader = nil },
}

local focusent = nil

-------------------------------------------------
-- Initialization & Resize
-------------------------------------------------

function RenderSystem:init()
    local w, h = love.graphics.getDimensions()
    self:resize(w, h)
end

function RenderSystem:resize(w, h)
    for _, name in ipairs(layerOrder) do
        layers[name].canvas = love.graphics.newCanvas(w, h)
        layers[name].canvas:setFilter("nearest", "nearest") -- optional, good for pixel art
    end
end

-------------------------------------------------
-- Shader API
-------------------------------------------------

function RenderSystem:setShader(layerName, shader)
    if layers[layerName] then
        layers[layerName].shader = shader
        return true
    end
    return false
end

function RenderSystem:getShader(layerName)
    return layers[layerName] and layers[layerName].shader or nil
end

function RenderSystem:clearShader(layerName)
    if layers[layerName] then
        layers[layerName].shader = nil
    end
end

function RenderSystem:clearAllShaders()
    for _, name in ipairs(layerOrder) do
        layers[name].shader = nil
    end
end

-------------------------------------------------
-- Drawing Helpers
-------------------------------------------------

local function drawSprite(sprite, x, y, data, facing)
    if not sprite then return end

    local r  = data.r or 0
    local sx = facing or data.sx or 1
    local sy = data.sy or 1
    local ox = data.ox or (data.width and data.width / 2 or 0)
    local oy = data.oy or (data.height and data.height / 2 or 0)

    if sprite.type == "animation" and sprite.animation then
        sprite.animation:draw(
            sprite.image,
            x + (data.width or 0) / 2,
            y + (data.height or 0) / 2,
            r, sx, sy, ox, oy
        )
    elseif sprite.type == "image" and sprite.image then
        love.graphics.draw(
            sprite.image,
            x + (data.width or 0) / 2,
            y + (data.height or 0) / 2,
            r, sx, sy, ox, oy
        )
    end
end

local function drawEntity(entity)
    if not entity.drawdata or entity.drawdata.drawable == false then
        return
    end

    -- Fallback rectangle if no sprite/animation
    if not entity.sprite and not entity.currentAnimation and not entity.animations then
        love.graphics.rectangle(
            "line",
            entity.x,
            entity.y,
            entity.drawdata.width or 32,
            entity.drawdata.height or 32
        )
        return
    end

    -- Prefer the new currentAnimation system
    if entity.currentAnimation then
        drawSprite(entity.currentAnimation, entity.x, entity.y, entity.drawdata, entity.facing)
        return
    end

    -- Backward compatibility (old state-based system)
    if entity.animations and entity.state then
        local anim = entity.animations[entity.state]
        if anim then
            drawSprite(anim, entity.x, entity.y, entity.drawdata, entity.facing)
        end
        return
    end

    -- Single sprite
    if entity.sprite then
        drawSprite(entity.sprite, entity.x, entity.y, entity.drawdata, entity.facing)
    end
end

-------------------------------------------------
-- Main Draw
-------------------------------------------------

function RenderSystem:draw(entities)
    local w, h = love.graphics.getDimensions()

    -- Safety: recreate canvases if needed
    if not layers.world.canvas or layers.world.canvas:getWidth() ~= w then
        self:resize(w, h)
    end

    -- 1. Clear all layer canvases
    for _, name in ipairs(layerOrder) do
        love.graphics.setCanvas(layers[name].canvas)
        love.graphics.clear(0, 0, 0, 0)
    end

    -- 2. Draw entities into their respective layer
    for _, entity in pairs(entities) do
        if entity.alive ~= false then
            local layerName = (entity.drawdata and entity.drawdata.layer) or "world"
            local layer = layers[layerName] or layers.world

            love.graphics.setCanvas(layer.canvas)
            drawEntity(entity)
        end
    end

    -- 3. Composite layers to the screen (with optional shaders)
    love.graphics.setCanvas()
    love.graphics.setColor(1, 1, 1, 1)

    for _, name in ipairs(layerOrder) do
        local layer = layers[name]

        if layer.shader then
            love.graphics.setShader(layer.shader)
        end

        love.graphics.draw(layer.canvas)

        love.graphics.setShader()
    end
end

-------------------------------------------------
-- Debug Drawing
-------------------------------------------------

function RenderSystem:focusdebugon(arg, arg2)
    local ECS = require("src.EntityComponentSystem")

    focusent = nil

    if arg == "name" then
        for _, entity in pairs(ECS.entities) do
            if entity.identity and entity.identity.name == arg2 then
                focusent = entity
                return true
            end
        end
    elseif arg == "tag" then
        for _, entity in pairs(ECS.entities) do
            if entity.identity and entity.identity.tags and entity.identity.tags[arg2] then
                focusent = entity
                return true
            end
        end
    elseif type(arg) == "number" then
        focusent = ECS.entities[arg]
    end

    return focusent ~= nil
end

function RenderSystem:drawdebuginworld(entities)
    for _, entity in pairs(entities) do
        if entity.alive == false then goto continue end

        -- Collider
        love.graphics.setColor(1, 0, 0, 0.8)
        if entity.collider then
            love.graphics.rectangle(
                "line",
                entity.x + (entity.collider.offsetx or 0),
                entity.y + (entity.collider.offsety or 0),
                entity.collider.width or 32,
                entity.collider.height or 32
            )
        else
            love.graphics.rectangle(
                "line",
                entity.x,
                entity.y,
                entity.drawdata and entity.drawdata.width or 32,
                entity.drawdata and entity.drawdata.height or 32
            )
        end
        love.graphics.setColor(1, 1, 1, 1)

        ::continue::
    end
end

function RenderSystem:drawdebugonscreen(entities)
    love.graphics.setColor(1, 1, 1, 1)

    local count = 0
    for _ in pairs(entities) do count = count + 1 end
    love.graphics.print("Entity count: " .. count, 10, 10)

    if focusent then
        local y = 40
        local function line(text)
            love.graphics.print(text, 10, y)
            y = y + 18
        end

        line("Focused: " .. (focusent.identity and focusent.identity.name or "unknown"))
        line("ID: " .. (focusent.identity and focusent.identity.id or "?"))
        line("Pos: " .. math.floor(focusent.x) .. ", " .. math.floor(focusent.y))
        if focusent.velocityx then
            line("Vel: " .. math.floor(focusent.velocityx) .. ", " .. math.floor(focusent.velocityy or 0))
        end
        line("Anim: " .. (focusent.currentAnimName or focusent.state or "none"))
        line("Grounded: " .. tostring(focusent.grounded))
    else
        love.graphics.print("No entity focused", 10, 40)
    end
end

return RenderSystem