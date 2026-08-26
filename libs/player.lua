local Player = {}
local assetsmanager = require("src/assetsmanager")
local physics = require("src/physics")

Player.__index = Player

function Player.new(x, y)
    local self = setmetatable({}, Player)

    self.x = x
    self.y = y

    self.spriteWidth = 94
    self.spriteHeight = 94

    self.velocityx = 0
    self.velocityy = 0

    self.acceleration = 1000
    self.maxspeed = 500
    self.dragval = 400

    self.gravity = 400
    self.jumpforce = 500

    self.animations = assetsmanager.loadpack("stickman")
    self.facing = 1
    self.state = "idle"
    self.anchored = false
    self.grounded = false

    self.collider = {
        offsetx = 24,
        offsety = 0,
        width = 47,
        height = 94
    }

    return self
end

function Player:jump()
    if self.grounded then
        self.velocityy = -self.jumpforce
        self.grounded = false
    end
end

function Player:update(dt)

    for _, anim in pairs(self.animations) do
        if anim.type == "animation" then
            anim.animation:update(dt)
        end
    end

    if love.keyboard.isDown("d") and not self.anchored then
        self.velocityx = self.velocityx + self.acceleration * dt
        self.facing = 1
    end

    if love.keyboard.isDown("a") and not self.anchored then
        self.velocityx = self.velocityx - self.acceleration * dt
        self.facing = -1
    end

    if self.velocityx ~= 0 and not (love.keyboard.isDown("a") and love.keyboard.isDown("d")) then
        physics.drag(self, dt)
    end

    if love.keyboard.isDown("d") and not self.anchored then
        self.facing = 1
    elseif love.keyboard.isDown("a") and not self.anchored then
        self.facing = -1
    end

    if self.velocityx > self.maxspeed then
        self.velocityx = self.maxspeed
    elseif self.velocityx < -self.maxspeed then
        self.velocityx = -self.maxspeed
    end

    if not self.grounded then
        self.state = "jumping"
    elseif love.keyboard.isDown("a") or love.keyboard.isDown("d") then
        self.state = "running"
    elseif math.abs(self.velocityx) > 5 then
        self.state = "sliding"
    else
        self.state = "idle"
    end
end

function Player:draw()
    local current = self.animations[self.state]

    if current.type == "animation" then
    current.animation:draw(
    current.image,
    self.x + self.spriteWidth / 2,
    self.y,
    0,
    self.facing,
    1,
    self.spriteWidth / 2,
    0
    )

    elseif current.type == "image" then
    love.graphics.draw(
    current.image,
    self.x + self.spriteWidth / 2,
    self.y,
    0,
    self.facing,
    1,
    self.spriteWidth / 2,
    0
    )
    end
end

return Player