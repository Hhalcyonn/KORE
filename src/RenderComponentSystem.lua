local RenderComponentSystem = {}

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

function RenderComponentSystem:draw(entitylist)
    for _, entity in ipairs(entitylist) do

        if entity.type == "structure" and not entity.image then
            love.graphics.rectangle(
                "line",
                entity.x,
                entity.y,
                entity.width,
                entity.height
            )
        elseif entity.image then
            drawsprite(entity.image, entity.x, entity.y, entity.drawdata, entity.facing)
        end

        if entity.animations and entity.state then
            local current = entity.animations[entity.state]

            if current then
                drawsprite(current, entity.x, entity.y, entity.drawdata, entity.facing)
            end
        elseif entity.animation and not entity.state then
            error("Atleast one of" .. entity.type .. "has animation but no state")
        end
    end
end

function RenderComponentSystem:drawdebuginworld(entitylist)
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

function RenderComponentSystem:drawdebugonscreen(entitylist)
    local player
    for _, entity in ipairs(entitylist) do
        if entity.type == "player" then
            player = entity
            break
        end
        player = nil
        break
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

return RenderComponentSystem

-- ANIMATED SPRITE MUST HAVE STATE! im too lazy to fix it