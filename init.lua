
local BASE = (...) .. "."

local KORE = {}

KORE.ECS = require(BASE .. "src.EntityComponentSystem")
KORE.AssetsSystem = require(BASE .. "src.AssetsSystem")
KORE.WorldSystem = require(BASE .. "src.WorldSystem")
KORE.RenderSystem = require(BASE .. "src.RenderSystem")
KORE.ConsoleSystem = require(BASE .. "src.Console")
KORE.Physics = require(BASE .. "src.PhysicsSystem")

KORE.images = KORE.AssetsSystem.images
KORE.sounds = KORE.AssetsSystem.sounds
KORE.fonts = KORE.AssetsSystem.fonts

KORE.libs = {
    anim8 = require(BASE .. "libs.anim8"),
    bump = require(BASE .. "libs.bump"),
    camera = require(BASE .. "libs.hump.camera"),
    timer = require(BASE .. "libs.hump.timer"),
    vector = require(BASE .. "libs.hump.vector"),
    class = require(BASE .. "libs.hump.class"),
    gamestate = require(BASE .. "libs.hump.gamestate")
}

local ECS = KORE.ECS
local AssetsSystem = KORE.AssetsSystem
local WorldSystem = KORE.WorldSystem
local RenderSystem = KORE.RenderSystem
local ConsoleSystem = KORE.ConsoleSystem
local PhysicsSystem = KORE.Physics

local images = KORE.images
local sounds = KORE.sounds
local fonts = KORE.fonts

local debug = false
local cam

function KORE.initAssetsPath(context)
    AssetsSystem.init(context)
end

function KORE.setCamera()
    cam = KORE.libs.camera()
    return cam
end

function KORE.unsetCamera()
    cam = nil
    return nil
end

function KORE.load()
    math.randomseed(os.time())
    AssetsSystem.loadimages()
    if WorldSystem.world then
        WorldSystem.addtoworld(ECS.entities)
    end
    ConsoleSystem:init({
        entities = ECS.entities,
        WorldSystem = WorldSystem,
        setDebug = function(value)
            debug = value
        end
    })
end

function KORE.update(dt)
    KORE.libs.timer.update(dt)
    PhysicsSystem.update(ECS.entities, dt)
    for _, entity in pairs(ECS.entities) do
        ECS.update(dt, entity)
    end
    ConsoleSystem:update()
    WorldSystem.update(ECS.entities, dt)
    ECS.removeDeadEntities()
end

function KORE.draw()
    if cam then
        cam:attach()
    end
    RenderSystem:draw(ECS.entities)
    if debug then
        RenderSystem:drawdebuginworld(ECS.entities)
    end
    if cam then
        cam:detach()
    end
    RenderSystem:drawdebugonscreen(ECS.entities)
    ConsoleSystem:draw()
end

function KORE.keypressed(key)
    ConsoleSystem:keypressed(key)
    for _, entity in pairs(ECS.entities) do
        ECS.onKeyPressed(key, entity)
    end
end

function KORE.mousepressed(x, y, button)
    for _, entity in pairs(ECS.entities) do
        ECS.onMousePressed(x, y, button, entity)
    end
end

function KORE.keyreleased(key)
    ConsoleSystem:keyreleased(key)
    for _, entity in pairs(ECS.entities) do
        ECS.onKeyReleased(key, entity)
    end
end

function KORE.textinput(text)
    ConsoleSystem:textinput(text)
end

function KORE.textedited(text, start, length)
    ConsoleSystem:textedited(text, start, length)
end

function KORE.setDebug(value)
    debug = value
end

function KORE.getDebug()
    return debug
end

function KORE.spawnEntity(data)
    local e = ECS.createentity(data)
    ECS.register(e)
    return e
end

return KORE