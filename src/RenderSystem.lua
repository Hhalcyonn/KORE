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
            x + data.spritewidth / 2,
            y + data.spriteheight / 2,
            r,
            sx,
            sy,
            data.spritewidth / 2,
            data.spriteheight / 2
        )

    elseif sprite.type == "image" then
        love.graphics.draw(
            sprite.image,
            x + data.spritewidth / 2,
            y + data.spriteheight / 2,
            r,
            sx,
            sy,
            data.spritewidth / 2,
            data.spriteheight / 2
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
            love.graphics.rectangle("line", entity.x, entity.y, entity.width, entity.height)
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
                entity.width,
                entity.height
            )
            love.graphics.setColor(1, 1, 1)
        end
    end
end

function RenderSystem:drawdebugonscreen(entitylist)
    local player
    for _, entity in pairs(entitylist) do
        if entity.type == "player" then
            player = entity
            break
        end
    end
    if player ~= nil then
        love.graphics.setColor(1,1,1)
        love.graphics.print("Player VelocityX: " .. math.floor(player.velocityx), 0, 280)
        love.graphics.print("Player VelocityY: " .. math.floor(player.velocityy), 0, 300)
        love.graphics.print("Player State: " .. player.state, 0, 320)
        love.graphics.print("Player Facing: " .. player.facing, 0, 340)
        if player.grounded then
            love.graphics.print("Player Grounded: true", 0, 360)
        else
            love.graphics.print("Player Grounded: false", 0, 360)
        end
    else
        love.graphics.print("No player found.", 0, 280)
    end
    local count = 0
    for _, entity in pairs(entitylist) do
        count = count + 1
    end
    love.graphics.print("Entity count: " .. count, 0, 380)
end

return RenderSystem

-- ANIMATED SPRITE MUST HAVE STATE! im too lazy to fix it