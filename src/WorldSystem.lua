local bump = require("libs/bump")

local WorldSystem = {}

WorldSystem.world = nil

local function collisionfilter(entity, other)
    local entityFilter = entity.collider.collisionfilter or "slide"
    local otherFilter = other.collider.collisionfilter or "slide"

    if entityFilter == "slide" or otherFilter == "slide" then
        return "slide"
    end

    return entityFilter
end

function WorldSystem.initworld(cellsize, worldpack)
    local ECS = require("src/EntityComponentSystem")
    WorldSystem.world = bump.newWorld(cellsize or 64)
    if worldpack then
        for _, structures in pairs(worldpack) do
            ECS.register(structures)
        end
    end
end

function WorldSystem.deleteworld()
    WorldSystem.world = nil
end

function WorldSystem.addtoworld(entitylist)
    if WorldSystem.world ~= nil then
        for _, entity in pairs(entitylist) do
            if entity.collider then
                if entity.collider.collision then
                    WorldSystem.world:add(
                        entity,
                        entity.x + entity.collider.offsetx,
                        entity.y + entity.collider.offsety,
                        entity.collider.width,
                        entity.collider.height
                    )
                end
                if (entity.collider.collision == false or entity.collider.collision == nil) and WorldSystem.world:hasItem(entity) then
                    WorldSystem.world:remove(entity)
                end
            end
        end
    end
end

function WorldSystem.update(entitylist, dt)
    for _, entity in pairs(entitylist) do
        if entity.velocityx ~= nil and entity.velocityy ~= nil then
            if entity.collider and entity.collider.collision and WorldSystem.world:hasItem(entity) then
                entity.grounded = false
                local goalx = entity.x + entity.velocityx * dt
                local goaly = entity.y + entity.velocityy * dt
                local actualx, actualy, cols, len =
                    WorldSystem.world:move(
                        entity,
                        goalx + entity.collider.offsetx,
                        goaly + entity.collider.offsety,
                        collisionfilter
                    )
                for i = 1, len do
                    local col = cols[i]

                    -- The collision is still registered here.
                    if col.type == "cross" then
                        if entity.onCollision then
                            entity.onCollision(col.item, col.other, dt)
                        end
                    elseif col.type == "slide" then
                        if entity.onCollision then
                            entity.onCollision(col.item, col.other, dt)
                        end
                        if col.normal.y < 0 then
                            entity.velocityy = 0
                            entity.grounded = true
                        elseif col.normal.y > 0 then
                            entity.velocityy = 0
                        end
                        if col.normal.x ~= 0 then
                            entity.velocityx = 0
                        end

                    elseif col.type == "touch" then
                        if entity.onCollision then
                            entity.onCollision(col.item, col.other, dt)
                        end
                        if col.normal.y < 0 then
                            entity.velocityy = 0
                            entity.grounded = true
                        elseif col.normal.y > 0 then
                            entity.velocityy = 0
                        end
                        if col.normal.x ~= 0 then
                            entity.velocityx = 0
                        end
                    elseif col.type == "bounce" then
                        if entity.onCollision then
                            entity.onCollision(col.item, col.other, dt)
                        end
                        if col.normal.y < 0 then
                            entity.velocityy = entity.velocityy * -1
                            entity.grounded = true
                        elseif col.normal.y > 0 then
                            entity.velocityy = -entity.velocityy
                        end
                        if col.normal.x ~= 0 then
                            entity.velocityx = -entity.velocityx
                        end
                    end
                end
                    entity.x = actualx - entity.collider.offsetx
                    entity.y = actualy - entity.collider.offsety
            else
                entity.x = entity.x + entity.velocityx * dt
                entity.y = entity.y + entity.velocityy * dt
            end
        end
    end
end

return WorldSystem