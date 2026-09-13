local BASE = "KORE."
local entitymethods = {}
local assets = require(BASE .. "src.AssetsSystem")
local ECS = require(BASE .. "src.EntityComponentSystem")
local PhysicsSystem = require(BASE .. "src.PhysicsSystem")
local log = require(BASE .. "src.log")

function entitymethods:followTo(target, speed, dt, centertype)
    if not self.physics then
        return
    end

    local physics = self.physics
    local velocity = physics.velocity

    speed = speed or (
        (physics.maxSpeed.x + physics.maxSpeed.y) / 2
    )

    local dx, dy = self:distanceToAxes(target, centertype or "Drawdata")
    local distance = self:distanceToSquared(target)

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

function entitymethods:distanceToAxes(target, y)
    local sx
    local sy
    local tx
    local ty

    if type(target) == "table" then
        if type(y) == "string" then
            if y == "Drawdata" then
                sx, sy = self:getCenter("Drawdata")
                tx, ty = target:getCenter("Drawdata")
            elseif y == "Collider" then
                sx, sy = self:getCenter("Collider")
                tx, ty = target:getCenter("Collider")
            end
        elseif y == nil then
            sx, sy = self:getCenter("Drawdata")
            tx, ty = target:getCenter("Drawdata")
        end
    elseif type(target) == "number" then
        sx, sy = self:getCenter("Drawdata")
        tx, ty = target, y
    end

    return tx - sx, ty - sy
end

function entitymethods:setState(newState, callback)
    if self.state == newState then
        return
    end
    if callback then
        callback(self)
    end
    self.state = newState
end

function entitymethods:getCenter(datatype)
    if datatype == "Drawdata" then
        return self.x,
            self.y
    elseif datatype == "Collider" then
        return self.x + (self.collider.offsetx or 0)
                + self.collider.width / 2,
            self.y + (self.collider.offsety or 0)
                + self.collider.height / 2
    else
        return self.x + self.drawdata.width / 2,
            self.y + self.drawdata.height / 2
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

function entitymethods:angleTo(target, y)
    if target then
        if type(target) == "table" then
            local tcx, tcy = target:getCenter("Collider")
            local scx, scy = self:getCenter("Collider")
            local dx = tcx - scx
            local dy = tcy - scy
            return math.atan2(dy, dx)
        elseif type(target) == "number" then
            local scx, scy = self:getCenter("Collider")
            local dx = target - scx
            local dy = y - scy
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

function entitymethods:isAnimPlaying(anim)
    if self.animations then
        return self.animdata.current == anim
    end
end

function entitymethods:onGrounded(callback)
    if self.physics.bodytype == "Dynamic" then
        if self.physics.grounded then
            if callback then
                callback(self, dt)
            end
        end
    end
end

function entitymethods:setLayer(layer)
    if layer and layer == "string" then
        entity.drawdata == layer
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

function entitymethods:lookAt(target, y, centerType)
    centerType = centerType or "Drawdata"

    local dx
    local dy

    if type(target) == "table" then
        dx, dy = self:distanceToAxes(target, centerType)
    else
        local sx, sy = self:getCenter(centerType)
        dx = target - sx
        dy = y - sy
    end

    self.drawdata.r = math.atan2(dy, dx)
end

function entitymethods:distanceToSquared(target, y)
    local tcx, tcy
    local scx, scy

    if type(target) == "table" then
        if type(y) == "string" then
            if y == "Drawdata" then
                tcx, tcy = target:getCenter(y)
                scx, scy = self:getCenter(y)
            elseif y == "Collider" then
                tcx, tcy = target:getCenter(y)
                scx, scy = self:getCenter(y)
            end
        else
            tcx, tcy = target:getCenter("Drawdata")
            scx, scy = self:getCenter("Drawdata")
        end
    else
        scx = self.x
        scy = self.y
        tcx = target
        tcy = y
    end


    local dx = tcx - scx
    local dy = tcy - scy
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

function entitymethods:clearForces()
    if self.physics and self.physics.bodytype == "Dynamic" then
        self.physics.force = {x = 0, y = 0}
    end
end

function entitymethods:setPosition(x, y)
    self.x = x
    self.y = y
end

function entitymethods:setBodytype(data)
    if data.bodytype == "Dynamic" then
        self.physics = {
            bodytype = "Dynamic",
            velocity = {x = data.velocity and data.velocity.x or 0, y = data.velocity and data.velocity.y or 0},
            force = {x = data.force and data.force.x or 0, y = data.force and data.force.y or 0},
            mass = data.mass or 1,
            gravityScale = data.gravityScale or 1,
            dragScale = data.dragScale or 1,
            frictionScale = data.frictionScale or 1,
            maxSpeed = {x = data.maxSpeed and data.maxSpeed.x or 1000, y = data.maxSpeed and data.maxSpeed.y or 2000},
            grounded = data.grounded or false,
            anchored = data.anchored or false,
            overSpeedMode = data.overSpeedMode or "clamp"
        }
    elseif data.bodytype == "Kinematic" then
        self.physics = {
            bodytype = "Kinematic",
            velocity = {x = data.velocity and data.velocity.x or 0, y = data.velocity and data.velocity.y or 0},
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
        elseif arg == "force" and type(arg2) == "table" then
            if data.bodytype == "Dynamic" then
                data.force = {x = arg2.x, y = arg2.y}
            else
                print("Attempted to change Force to a non Dynamic bodytype entity.")
            end
        end
    end
end

function entitymethods:isAnchored()
    return self.physics.anchored
end

function entitymethods:heal(value)
    if entity.health then entity.health.current = entity.health.current + value end
end

function entitymethods:damage(value)
    if entity.health then entity.health.current = entity.health.current - value end
end

function entitymethods:flip(value)
    if value == nil then
        if self.facing == 1 then
            self.facing = -1
        elseif self.facing == -1 then
            self.facing = 1
        end
    else
        if value == 1 then
            self.facing = value
        elseif value == -1 then
            self.facing = value
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
    if self.physics and self.physics.bodytype == "Dynamic" then
        return self.physics.grounded
    else
        warn()
    end
end

function entitymethods:stop()
    if self.physics and self.physics.bodytype == "Dynamic" then
        self.physics.velocity = {x = 0, y = 0}
        self.physics.force = {x = 0, y = 0}
    elseif self.physics and self.physics.bodytype == "Kinematic" then
        self.physics.velocity = {x = 0, y = 0}
    end
end

function entitymethods:setVelocity(vx, vy)
    if self.physics
        and (self.physics.bodytype == "Dynamic"
            or self.physics.bodytype == "Kinematic") then
        self.physics.velocity = {
            x = vx,
            y = vy
        }
    end
end

function entitymethods:setAnchored(bool)
    if entity.physics and entity.physics.bodytype ~= "Static" then
        entity.physics.anchored = bool
    end
end

function entitymethods:setCollider(data)
    if data then
        self.collider.collision = data.collision or self.collider.collision
        self.collider.collisionfilter = data.collisionfilter or self.collider.collisionfilter
        self.collider.width = data.width or self.collider.width
        self.collider.height = data.height or self.collider.height
        self.collider.offsetx = data.offsetx or self.collider.offsetx
        self.collider.offsety = data.offsety or self.collider.offsety
    end
end

function entitymethods:setDrawdata(data)
    self.drawdata.drawable = data.drawable or self.drawdata.drawable
    self.drawdata.width = data.width or self.drawdata.width
    self.drawdata.height = data.height or self.drawdata.height
    self.drawdata.r = data.r or self.drawdata.r
    self.drawdata.sx = data.sx or self.drawdata.sx
    self.drawdata.sy = data.sy or self.drawdata.sy
    self.drawdata.ox = data.ox or self.drawdata.ox
    self.drawdata.oy = data.oy or self.drawdata.oy
    self.drawdata.kx = data.kx or self.drawdata.kx
    self.drawdata.ky = data.ky or  self.drawdata.ky
    self.drawdata.layer = data.layer or self.drawdata.layer
end

function entitymethods:hasTag(tag)
    return self.identity.tags[tag]
end

function entitymethods:addTag(tag)
    if tag then
        table.insert(self.identity.tags, tag)
    end
end

function entitymethods:removeTag(tag)
    if tag then
        table.remove(self.identity.tags, tag)
    end
end

return entitymethods