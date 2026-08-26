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

        if entity.entitytype == "structure" and not entity.image then
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

return RenderComponentSystem

-- ANIMATED SPRITE MUST HAVE STATE! im too lazy to fix it