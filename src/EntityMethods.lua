local entitymethods = {}

function entitymethods:moveTo(target, speed, dt)
    speed = speed or self.maxspeed

    local selfCenterX = self.x + self.drawdata.width / 2
    local selfCenterY = self.y + self.drawdata.height / 2
    local targetCenterX = target.x + target.drawdata.width / 2
    local targetCenterY = target.y + target.drawdata.height / 2
    local dragval = self.dragval
    local acceleration = self.acceleration or nil
    local dx = targetCenterX - selfCenterX
    local dy = targetCenterY - selfCenterY
    local distance = self:distanceTo(target)

    if dx == 0 and dy == 0 and dragval == 0 then
        self.velocityx = 0
        self.velocityy = 0
        return
    end

    local angle = math.atan2(dy, dx)
    if distance ~= 0 then
        if acceleration then
            local accelerationStep = acceleration * (dt or 0)
            self.velocityx = self.velocityx + math.cos(angle) * accelerationStep
            self.velocityy = self.velocityy + math.sin(angle) * accelerationStep

            local velocity = math.sqrt(self.velocityx * self.velocityx + self.velocityy * self.velocityy)
            if velocity > speed then
                local scale = speed / velocity
                self.velocityx = self.velocityx * scale
                self.velocityy = self.velocityy * scale
            end
        else
            self.velocityx = math.cos(angle) * speed
            self.velocityy = math.sin(angle) * speed
        end
    end
end

function entitymethods:Destroy(entity)
    self.alive = false
end

function entitymethods:setState(newState)
    if self.state == newState then
        return
    end

    self.state = newState
end

function entitymethods:switchAnimation(animName, forceReset)
    if self.animdata.current == animName and not forceReset then
        return
    end
    self.animations[self.animdata.current].previousframe = 0
    local anim = self.animations[animName].animation
    if not anim then print ("No anim for " .. animName ) return end

    self.animdata.current = animName

    anim.animation:gotoFrame(1)
    anim.previousframe = 0
    anim.animation:resume()
end

function entitymethods:enteredFrame(frame, animationstate)
    if self.animations and animationstate then
        if self.animations[animationstate] then
            local anim = self.animations[animationstate].animation
            local previousframe = self.animations[animationstate].previousframe
            if anim ~= nil then
                return (anim.position == frame) and (previousframe ~= frame)
            end
        end
    end
end

function entitymethods:faceTo(target)
    if not target or not target.x or not target.y then
        return
    end
    if not self.drawdata then
        return
    end
    if not self.x or not self.y then
        return
    end
    local dx = target.x - self.x
    local dy = target.y - self.y
    self.drawdata.r = math.atan2(dy, dx)
end

function entitymethods:distanceTo(target, y)
    local tx, ty

    if type(target) == "table" then
        -- It's an entity (or anything with x/y)
        tx = target.x
        ty = target.y

        -- Optional: use center if it has width/height or collider
        if target.collider then
            tx = tx + (target.collider.offsetx or 0) + target.collider.width / 2
            ty = ty + (target.collider.offsety or 0) + target.collider.height / 2
        end
    else
        -- Assume two numbers were passed: distanceTo(x, y)
        tx = target
        ty = y
    end

    local sx, sy = self.x, self.y
    if self.collider then
        sx = sx + (self.collider.offsetx or 0) + self.collider.width / 2
        sy = sy + (self.collider.offsety or 0) + self.collider.height / 2
    end

    local dx = tx - sx
    local dy = ty - sy
    return math.sqrt(dx*dx + dy*dy)
end


function entitymethods:getCoordinates()
    local x, y = self.x, self.y
    return x, y
end

function entitymethods:setPosition(x, y)
    self.x = x
    self.y = y
end

function entitymethods:setBodytype(data)
    if data.bodytype == "Dynamic" then
        entity.physics = {
            bodytype = "Dynamic",
            velocity = {x = data.velocity.x or 0, y = data.velocity.y or 0},
            force = {x = data.force.x 0, y = data.force.y or 0},
            mass = data.mass or 1,
            gravityScale = data.gravityScale or 1,
            dragScale = data.dragScale or 1,
            frictionScale = data.physics.frictionScale or 1,
            maxSpeed = {x = data.maxSpeed.x or 1000, y = data.maxSpeed.y or 2000}
            grounded = data.grounded or false,
            anchored = data.physics.anchored or false
        }
    elseif data.bodytype == "Kinematic" then
        entity.physics = {
            bodytype = "Kinematic",
            velocity = {x = data.velocity.x or 0, data.velocity.y = 0},
            maxSpeed = {x = data.maxSpeed.x or 1000, y = data.maxSpeed.y or 2000}
            anchored = data.anchored or false
        }
    elseif data.bodytype == "Static" then
        entity.physics = {
            bodytype = "Static",
            anchored = true
        }
    else
        error(data.bodytype .. " Is not a Bodytype.", 2)
    end
end

function entitymethods:setPhysics(arg, arg2)
    local data = self.physics
    if data then
        if arg == "gravityScale" and type(arg2) == "number" then
            if data.bodytype == "Dynamic" then
                self.physics.gravityScale = arg2
            else
               print("Attempted to change gravityScale to a non Dynamic bodytype entity.") 
            end
        end
    end
end

function entitymethods:getIdentity(arg, arg2)
    if arg == "name" then
        return self.identity.name
    elseif arg == "id" then
        return self.identity.id
    elseif arg == "tag" then
        return self.identity.tags[arg2]
    elseif arg == "all" then
        local name, id, tags = self.identity.name, self.identity.id, self.identity.tags
        return name, id, tags
    else
        return nil
    end
end

return entitymethods