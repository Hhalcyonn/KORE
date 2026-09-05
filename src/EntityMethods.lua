local entitymethods = {}

function entitymethods:moveTo(target, speed, dt)
    speed = speed or self.maxspeed

    local selfCenterX = self.x + self.drawdata.spritewidth / 2
    local selfCenterY = self.y + self.drawdata.spriteheight / 2
    local targetCenterX = target.x + target.drawdata.spritewidth / 2
    local targetCenterY = target.y + target.drawdata.spriteheight / 2
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
    local anim = self.animations[newState]
    if anim and anim.animation then
        anim.animation:gotoFrame(1)
    end
end

function entitymethods:enteredFrame(frame)
    if self.animations and self.state then
        local anim = self.animations[self.state].animation
        if anim ~= nil then
            return (anim.position == frame) and (self.animdata.previousframe ~= frame)
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

function entitymethods:distanceTo(target)
    local tx, ty

    if type(target) == "table" then
        -- It's an entity (or anything with x/y)
        tx = target.x
        ty = target.y

        -- Optional: use center if it has width/height or collider
        if target.collider then
            tx = tx + (target.collider.offsetx or 0) + target.collider.width / 2
            ty = ty + (target.collider.offsety or 0) + target.collider.height / 2
        elseif target.width and target.height then
            tx = tx + target.width / 2
            ty = ty + target.height / 2
        end
    else
        -- Assume two numbers were passed: distanceTo(x, y)
        tx = target
        ty = select(2, ...)
    end

    local sx, sy = self.x, self.y
    if self.collider then
        sx = sx + (self.collider.offsetx or 0) + self.collider.width / 2
        sy = sy + (self.collider.offsety or 0) + self.collider.height / 2
    elseif self.width and self.height then
        sx = sx + self.width / 2
        sy = sy + self.height / 2
    end

    local dx = tx - sx
    local dy = ty - sy
    return math.sqrt(dx*dx + dy*dy)
end

function entitymethods:getVelocities()
    local vx, vy = self.velocityx, self.velocityy
    return vx, vy
end

function entitymethods:getCoordinates()
    local x, y = self.x, self.y
    return x, y
end

function entitymethods:setPosition(x, y)
    self.x = x
    self.y = y
end

function entitymethods:setPhysics(gravity, dragval, maxspeed, collision)
    if type(gravity) == "number" then
        if gravity >= 0 then self.gravity = gravity end
        if dragval and dragval >= 0 then self.dragval = dragval end
        if maxspeed and maxspeed >= 0 then self.maxspeed = maxspeed end
        if collision then self.collider.collision = collision end
        return
    end


    if gravity == "ignorephysics" then
        self.gravity = 0
        self.dragval = 0
        self.maxspeed = 0
        self.collider.collision = false
    elseif gravity == "ignorephysicsbutcollision" then
        self.gravity = 0
        self.dragval = 0
        self.maxspeed = 0
    elseif gravity == "zerogravity" then
        self.gravity = 0
    elseif gravity == "nodrag" then
        self.dragval = 0
    elseif gravity == "nomaxspeed" then
        self.maxspeed = 0
    elseif gravity == "colfilter" then
        if dragval == "slide" then
            self.collider.collisionfilter = "slide"
        elseif dragval == "cross" then
            self.collider.collisionfilter = "cross"
        elseif dragval == "bounce" then
            self.collider.collisionfilter = "bounce"
        elseif dragval == "touch" then
            self.collider.collisionfilter = "touch"
        end
    elseif gravity == "collision" then
        self.collider.collision = dragval
    end
end

function entitymethods:getIdentity(arg, arg2)
    if arg == "name" then
        return self.identity.name
    elseif arg == "id" then
        return self.identity.id
    elseif arg == "tag" then
        return self.identity.tags[arg2]
    else
        local name, id, tags = self.identity.name, self.identity.id, self.identity.tags
        return name, id, tags
    end
end

return entitymethods