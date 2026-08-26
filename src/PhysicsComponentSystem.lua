local PhysicsComponentSystem = {}

function PhysicsComponentSystem.gravity(obj, dt)
    if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
        obj.velocityy = obj.velocityy + obj.gravity * dt
    end
end

function PhysicsComponentSystem.applygravityingroups(objs, dt) -- only a test
    for _, obj in ipairs(objs) do
        if obj.gravity and obj.gravity ~= 0 and obj.velocityy then
            obj.velocityy = obj.velocityy + obj.gravity * dt
        end
    end
end

function PhysicsComponentSystem.drag(obj, dt)
    if obj.dragval and obj.dragval ~= 0 and obj.velocityx then
        local dragForce = obj.dragval * dt
        if obj.velocityx > 0 then
            obj.velocityx = math.max(0, obj.velocityx - dragForce)
        elseif obj.velocityx < 0 then
            obj.velocityx = math.min(0, obj.velocityx + dragForce)
        end
    end
end

return PhysicsComponentSystem