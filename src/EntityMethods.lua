local BASE = (...) .. "."
local entitymethods = {}
local assets = require(BASE .. "src.AssetsSystem")
local ECS = require(BASE .. "src.EntityComponentSystem")
local PhysicsSystem = require(BASE .. "src.PhysicsSystem")
local log = require(BASE .. "src.log")

function entitymethods:followTo(target, speed, dt)
    if not self.physics then
        return
    end

    local physics = self.physics
    local velocity = physics.velocity

    speed = speed or (
        (physics.maxSpeed.x + physics.maxSpeed.y) / 2
    )

    local selfCenterX, selfCenterY = self:getCenter("Collider")

    local targetCenterX, targetCenterY = target:getCenter("Collider")


    local dx = targetCenterX - selfCenterX
    local dy = targetCenterY - selfCenterY
    local distance = self:distanceTo(target)

    if distance == 0 then
        velocity.x = 0
        velocity.y = 0
        physics.force.x = 0
        physics.force.y = 0
        return
    end

    local angle = math.atan2(dy, dx)

    local desiredVelocityX = math.cos(angle) * speed
    local desiredVelocityY = math.sin(angle) * speed

    local dt = dt or 0

    if dt <= 0 then
        velocity.x = desiredVelocityX
        velocity.y = desiredVelocityY
        return
    end

    local targetVelocityX = desiredVelocityX
    local targetVelocityY = desiredVelocityY

    local mass = (physics.mass and physics.mass > 0)
        and physics.mass
        or 1

    physics.force.x = (targetVelocityX - velocity.x) / dt
    physics.force.y = (targetVelocityY - velocity.y) / dt
end

function entitymethods:Destroy()
    self.alive = false
end

function entitymethods:distanceToAxes(target, useCenter)
    local sx, sy = self.x, self.y
    local tx, ty = target.x, target.y
    
    if useCenter then
        sx, sy = self:getCenter("Collider")
        tx, ty = target:getColliderCenter("Collider")
    end

    return tx - sx, ty - sy
end

function entitymethods:setState(newState, func)
    if self.state == newState then
        return
    end
    if func then
        func(self)
    end
    self.state = newState
end

function entitymethods:getCenter(datatype)
    if datatype == "Drawdata" then
        local cx, cy = self.x + self.drawdata.width/2, self.y + self.drawdata.height/2
        return cx, cy
    elseif datatype == "Collider" then
        local cx, cy = self.x + self.collider.width/2, self.y + self.collider.height/2
        return cx, cy
    end
end

function entitymethods:switchAnimation(animName, forceReset)
    if self.animations then
        if self.animdata.current == animName and not forceReset then
            return
        end
        if self.animdata.current ~= nil then
            self.animations[self.animdata.current].previousframe = 0
        end
        local anim = self.animations[animName]
        if not anim then print ("No anim for " .. animName ) return end

        self.animdata.current = animName

        anim.animation:gotoFrame(1)
        anim.previousframe = 0
        anim.animation:resume()
    end
end

function entitymethods:angleTo(target, arg2)
    if target then
        if ECS.entities[target.identity.id] ~= nil then
            local tcx, tcy = target:getCenter("Collider")
            local scx, scy = self:getCenter("Collider")
            local dx = tcx - scx
            local dy = tcy - scy
            return math.atan2(dy, dx)
        end
    end
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

function entitymethods:addAnimCapability(animationpack)
    if self.sprite then
        self.sprite = nil
    end
    if animationpack and not self.animations then
        self.animations = assets.loadpack(
            animationpack,
            "anim8anim"
        )
        self.animdata = {
            current = nil
        }
    end
end

function entitymethods:changeAnimPack(animationpack)
    if animationpack then
        self.animations = assets.loadpack(
            animationpack,
            "anim8anim"
        )
    end
end

function entitymethods:pauseCurrentAnim()
    if self.animations then
        local currentAnim = self.animations[self.animdata.current].animation
        currentAnim:pause()
    end
end

function entitymethods:resumeCurrentAnim()
    if self.animations then
        local currentAnim = self.animations[self.animdata.current].animation
        currentAnim:resume()
    end
end

function entitymethods:removeAnimCapability()
    if self.animations then
        self.animations = nil
        self.animdata = nil
    end
end

function entitymethods:addSpriteCapability(sprite)
    if self.animations then
        self.animations = nil
        self.animdata = nil
    end
    self.sprite = {
    type = "image",
    image = assets.images[sprite]
    }
end

function entitymethods:removeSpriteCapability()
    if self.sprite then
        self.sprite = nil
    end
end

function entitymethods:changeSprite(sprite)
    if sprite then
        self.sprite = {
            type = "image",
            image = assets.images[sprite]
        }
    end
end

function entitymethods:applyForce(fx, fy)
    if self.physics.bodytype == "Dynamic" then
        self.physics.force.x = self.physics.force.x + fx
        self.physics.force.y = self.physics.force.y + fy
    end
end

function entitymethods:applyImpulse(ix, iy)
    if self.physics.velocity and self.physics.mass then
        self.physics.velocity.x = self.physics.velocity.x + (ix / self.physics.mass)
        self.physics.velocity.y = self.physics.velocity.y + (iy / self.physics.mass)
    elseif self.physics.velocity and not self.physics.mass then
        self.physics.velocity.x = self.physics.velocity.x + ix
        self.physics.velocity.y = self.physics.velocity.y + iy
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

function entitymethods:getVelocities()
    local vx, vy = self.physics.velocity.x, self.physics.velocity.y
    return vx, vy
end

function entitymethods:setPosition(x, y)
    self.x = x
    self.y = y
end

function entitymethods:setBodytype(data)
    if data.bodytype == "Dynamic" then
        self.physics = {
            bodytype = "Dynamic",
            velocity = {x = data.velocity.x or 0, y = data.velocity.y or 0},
            force = {x = data.force.x or 0, y = data.force.y or 0},
            mass = data.mass or 1,
            gravityScale = data.gravityScale or 1,
            dragScale = data.dragScale or 1,
            frictionScale = data.frictionScale or 1,
            maxSpeed = {x = data.maxSpeed.x or 1000, y = data.maxSpeed.y or 2000},
            grounded = data.grounded or false,
            anchored = data.anchored or false,
            overSpeedMode = data.overSpeedMode or "clamp"
        }
    elseif data.bodytype == "Kinematic" then
        self.physics = {
            bodytype = "Kinematic",
            velocity = {x = data.velocity.x or 0, y = data.velocity.y or 0},
            maxSpeed = {x = data.maxSpeed.x or 1000, y = data.maxSpeed.y or 2000},
            anchored = data.anchored or false,
            frictionScale = data.frictionScale or 1
        }
    elseif data.bodytype == "Static" then
        self.physics = {
            bodytype = "Static",
            anchored = true,
            frictionScale = data.frictionScale or 1
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
                data.gravityScale = arg2
            else
               print("Attempted to change gravityScale to a non Dynamic bodytype entity.") 
            end
        elseif arg == "dragScale" and type(arg2) == "number" then
            if data.bodytype == "Dynamic" then
                data.dragScale = arg2
            else
                print("Attempted to change dragScale to a non Dynamic bodytype entity.") 
            end
        elseif arg == "frictionScale" and type(arg2) == "number" then
            data.frictionScale = arg2
        elseif arg == "mass" and type(arg2) == "number" then
            if data.bodytype == "Dynamic" then
                data.mass = arg2
            else
                print("Attempted to change mass to a non Dynamic bodytype entity.") 
            end
        elseif arg == "velocity" and type(arg2) == "table" then
            if data.bodytype == "Dynamic" or data.bodytype == "Kinematic" then
                data.velocity = {x = arg2.x, y = arg2.y}
            else
                print("Attempted to change velocity to a non Dynamic/Kinematic bodytype entity.") 
            end
        elseif arg == "maxSpeed" and type(arg2) == "table" then
            if data.bodytype == "Dynamic" then
                data.maxSpeed = {x = arg2.x, y = arg2.y}
            else
                print("Attempted to change velocity to a non Dynamic/Kinematic bodytype entity.") 
            end
        elseif arg == "grounded" and type(arg2) == "boolean" then
            if data.bodytype == "Dynamic" then
                data.grounded = arg2
            else
                print("Attempted to change grounded to a non Dynamic bodytype entity.")
            end
        elseif arg == "anchored" and type(arg2) == "boolean" then
            if data.bodytype ~= "Static" then
                data.anchored = arg2
            else
                print("Attempted to change anchored to a Static bodytype entity.")
            end
        elseif arg == "overSpeedMode" and type(arg2) == "string" then
            if data.bodytype == "Dynamic" then
                data.overSpeedMode = arg2
            else
                print("Attempted to change anchored to a non Dynamic bodytype entity.")
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

function entitymethods:isGrounded()
    return entity.physics and entity.physics.grounded
end


function entitymethods:setVelocity(vx, vy)
    if data then
        entity.physics.velocity = {x = data.x, y = data.y}
    end
end

return entitymethods