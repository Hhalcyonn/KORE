local BASE = "KORE."
local log = require(BASE .. "src.log")
local RenderSystem = {}

local layerOrder = { "background", "world", "foreground", "ui" }

local layers = {
    background = { canvas = nil, shader = nil },
    world      = { canvas = nil, shader = nil },
    foreground = { canvas = nil, shader = nil },
    ui         = { canvas = nil, shader = nil },
}

RenderSystem.onscreendebug = function(entitylist) then end
RenderSystem.inworlddebug = function(entitylist) then end

function RenderSystem.screendebug(func)
    if func then
        RendderSystem.onscreendebug = func
    end
end

function RenderSystem.worlddebug(func)
    if func then
        RendderSystem.inworlddebug = func
    end
end

function RenderSystem:init()
    local w, h = love.graphics.getDimensions()
    log.info("Render system initializing: " .. w .. "x" .. h)
    self:resize(w, h)
end

function RenderSystem:resize(w, h)
    for _, name in ipairs(layerOrder) do
        layers[name].canvas = love.graphics.newCanvas(w, h)
        layers[name].canvas:setFilter("nearest", "nearest")
    end
end

function RenderSystem:setShader(layerName, shader)
    if layers[layerName] then
        layers[layerName].shader = shader
        log.debug(tostring(shader) .. " Shader assigned to layer: " .. layerName)
        return true
    end
    log.warn("Cannot assign shader to unknown layer: " .. tostring(layerName))
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

local function drawSprite(sprite, cx, cy, data, facing)
    if not sprite then return end

    local r  = data.r or 0
    local sx = facing or data.sx or 1
    local sy = data.sy or 1
    local ox = data.ox or data.width / 2
    local oy = data.oy or data.height / 2
    local kx = data.kx or 0
    local ky = data.ky or 0

    if sprite.type == "animation" and sprite.animation then
        sprite.animation:draw(
            sprite.image,
            cx,
            cy,
            r, sx, sy, ox, oy, kx, ky
        )
    elseif sprite.type == "image" and sprite.image then
        love.graphics.draw(
            sprite.image,
            cx,
            cy,
            r, sx, sy, ox, oy kx, ky
        )
    end
end

local function drawEntity(entity)
    if not entity.drawdata or entity.drawdata.drawable == false then
        return
    end

    if not entity.sprite and not entity.animations then
        love.graphics.rectangle(
            "line",
            entity.x,
            entity.y,
            entity.drawdata.width or 32,
            entity.drawdata.height or 32
        )
        return
    end

    if entity.animations and entity.animdata.current ~= nil then
        local anim = entity.animations[entity.animdata.current]
        if anim then
            local cx, cy = entity:getCenter("Drawdata")
            drawSprite(anim, cx, cy, entity.drawdata, entity.facing)
        end
        return
    end

    if entity.sprite then
        local cx, cy = entity:getCenter("Drawdata")
        drawSprite(entity.sprite, cx, cy, entity.drawdata, entity.facing)
    end
end

function RenderSystem:draw(entities)
    local w, h = love.graphics.getDimensions()

    if not layers.world.canvas or layers.world.canvas:getWidth() ~= w or layers.world.canvas:getHeight() ~= h then
        self:resize(w, h)
    end

    for _, name in ipairs(layerOrder) do
        love.graphics.setCanvas(layers[name].canvas)
        love.graphics.clear(0, 0, 0, 0)
    end

    for _, entity in pairs(entities) do
        if entity.alive ~= false then
            local layerName = (entity.drawdata and entity.drawdata.layer) or "world"
            local layers
            if layers[layerName] then
                layer = layers[layerName]
            else
                log.warn("Unknown render layer '" .. tostring(layerName) .. "', using world layer")
                layer = layers["world"]
            end

            love.graphics.setCanvas(layer.canvas)
            drawEntity(entity)
        end
    end

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

function RenderSystem:drawdebuginworld(entities)
    for _, entity in pairs(entities) do
        if entity.alive == false then goto continue end

        love.graphics.setColor(1, 0, 0, 0.8)
        love.graphics.rectangle(
            "line",
            entity.x + (entity.collider.offsetx or 0),
            entity.y + (entity.collider.offsety or 0),
            entity.collider.width or 32,
            entity.collider.height or 32
            )
        love.graphics.setColor(0, 0, 1, 0.8)
        love.graphics.rectangle(
            "line",
            entity.x,
            entity.y,
            entity.drawdata and entity.drawdata.width or 32,
            entity.drawdata and entity.drawdata.height or 32
            )
        love.graphics.setColor(1, 1, 1, 1)
        local cx, cy = entity:getCenter("Drawdata")
        local idText = "ID: " .. entity.identity.id
        local textWidth = love.graphics.getFont():getWidth(idText)

        love.graphics.print(idText, cx - textWidth / 2, cy - (entity.drawdata.height or 32) / 2 - 12)
        RenderSystem.inworlddebug(entities)

        ::continue::
    end
end

function RenderSystem:drawdebugonscreen(entities)
    love.graphics.setColor(1, 1, 1, 1)

    local count = 0
    for _ in pairs(entities) do count = count + 1 end
    love.graphics.print("Entity count: " .. count, 10, 10)

    RenderSystem.onscreendebug(entities)

end

return RenderSystem