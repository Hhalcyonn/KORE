local bump = require("libs/bump")

local WorldSystem = {}

WorldSystem.world = nil

local function collisionfilter(entity, other)
    local entityFilter = entity.collisionfilter or "slide"
    local otherFilter = other.collisionfilter or "slide"

    if entityFilter == "slide" or otherFilter == "slide" then
        return "slide"
    end

    return entityFilter
end

function WorldSystem.initworld(cellsize, worldpack)
    WorldSystem.world = bump.newWorld(cellsize or 64)
end


function WorldSystem.addtoworld(entitylist)
    for _, entity in ipairs(entitylist) do
        if entity.collision then
            if entity.collider then
                WorldSystem.world:add(
                    entity,
                    entity.x + entity.collider.offsetx,
                    entity.y + entity.collider.offsety,
                    entity.collider.width,
                    entity.collider.height
                )
            elseif entity.x and entity.y and entity.width and entity.height then
                WorldSystem.world:add(
                    entity,
                    entity.x,
                    entity.y,
                    entity.width,
                    entity.height
                )
            else
                error("Atleast one entity has invalid collider or x, y, width and height for BUMP collision.")
            end
        end
    end
end

function WorldSystem.removefromworld(entity)
    if WorldSystem.world:hasItem(entity) then
        WorldSystem.world:remove(entity)
    end
end

function WorldSystem.update(entitylist, dt)
    for _, entity in pairs(entitylist) do
        if entity.velocityx ~= nil and entity.velocityy ~= nil then
            if entity.collider and entity.collision and WorldSystem.world:hasItem(entity) then
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
                        if entity.collisionlogic then
                            entity.collisionlogic(col.item, col.other)
                        end
                    elseif col.type == "slide" then
                        if entity.collisionlogic then
                            entity.collisionlogic(col.item, col.other)
                        else
                            if col.normal.y < 0 then
                                entity.velocityy = 0
                                entity.grounded = true
                            elseif col.normal.y > 0 then
                                entity.velocityy = 0
                            end
                            if col.normal.x ~= 0 then
                                entity.velocityx = 0
                            end
                        end
                    elseif col.type == "stick" then
                        if entity.collisionlogic then
                            entity.collisionlogic(col.item, col.other)
                        else
                            if col.normal.y < 0 then
                                entity.velocityy = 0
                                entity.grounded = true
                            elseif col.normal.y > 0 then
                                entity.velocityy = 0
                            end
                            if col.normal.x ~= 0 then
                                entity.velocityx = 0
                            end
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