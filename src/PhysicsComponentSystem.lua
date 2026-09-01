local PhysicsComponentSystem = {}
local deltatime
function PhysicsComponentSystem.initializedt(dt)
    deltatime = dt
end

function PhysicsComponentSystem.gravity(obj)
    if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
        obj.velocityy = obj.velocityy + obj.gravity * deltatime
    end
end

function PhysicsComponentSystem.applygravityingroups(objs) -- only a test
    for _, obj in ipairs(objs) do
        if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
            obj.velocityy = obj.velocityy + obj.gravity * deltatime
        end
    end
end

function PhysicsComponentSystem.drag(obj)
    if obj.appliedDragval and obj.appliedDragval ~= 0 and obj.velocityx then
        local dragForce = obj.appliedDragval * deltatime
        if obj.velocityx > 0 then
            obj.velocityx = math.max(0, obj.velocityx - dragForce)
        elseif obj.velocityx < 0 then
            obj.velocityx = math.min(0, obj.velocityx + dragForce)
        end
    end
end

return PhysicsComponentSystem