local log = require(BASE .. "src.log")
local RenderSystem = {}

local layerOrder = { "background", "world", "foreground", "ui" }

local layers = {
    background = { canvas = nil, shader = nil },
    world      = { canvas = nil, shader = nil },
    foreground = { canvas = nil, shader = nil },
    ui         = { canvas = nil, shader = nil },
}

local focusent = nil

function RenderSystem:init()
    local w, h = love.graphics.getDimensions()
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

local function drawSprite(sprite, cx, cy, data, facing)
    if not sprite then return end

    local r  = data.r or 0
    local sx = facing or data.sx or 1
    local sy = data.sy or 1
    local ox = data.ox or data.width / 2
    local oy = data.oy or data.height / 2

    if sprite.type == "animation" and sprite.animation then
        sprite.animation:draw(
            sprite.image,
            cx,
            cy,
            r, sx, sy, ox, oy
        )
    elseif sprite.type == "image" and sprite.image then
        love.graphics.draw(
            sprite.image,
            cx,
            cy,
            r, sx, sy, ox, oy
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
            local layer = layers[layerName] or layers.world

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

function RenderSystem:focusdebugon(arg, arg2)
    local ECS = require(BASE .. "src.EntityComponentSystem")

    focusent = nil

    if arg == "name" then
        for _, entity in pairs(ECS.entities) do
            if entity.identity and entity.identity.name == arg2 then
                focusent = entity
                return true
            end
        end
    elseif arg == "tag" then
        ECS.getEntityByIdentity("tag", arg2)
    elseif type(arg) == "number" then
        focusent = ECS.entities[arg]
    end

    return focusent ~= nil
end

function RenderSystem:drawdebuginworld(entities)
    for _, entity in pairs(entities) do
        if entity.alive == false then goto continue end

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
        if focusent.physics and focusent.physics.velocity then
            local vx, vy = focusent:getVelocities()
            line("Vel: " .. math.floor(vx) .. ", " .. math.floor(vy))
        end
        if entity.animations then
            line("Anim: " .. (focusent.animdata.current or "none"))
        end
        line("State: " .. (focusent.state or "none"))
        line("Anim: " .. (focusent.animdata and focusent.animdata.current or "none"))
        line("Grounded: " .. tostring(
            focusent.physics and focusent.physics.grounded or false
        ))
    else
        love.graphics.print("No entity focused", 10, 40)
    end
end

return RenderSystem