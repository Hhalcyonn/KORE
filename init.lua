local KORE = {}
local src =  require("src/init")

ECS = src.ECS
AssetsSystem = src.AssetsSystem
WorldSystem = src.WorldSystem
RenderSystem = src.RenderSystem
ConsoleSystem = src.Console
Prefabs = src.Prefabs
Physics = src.Physics
images = src.AssetsSystem.images
sounds = src.AssetsSystem.sounds
fonts = src.AssetsSystem.fonts

KORE.ECS = src.ECS
KORE.AssetsSystem = src.AssetsSystem
KORE.WorldSystem = src.WorldSystem
KORE.RenderSystem = src.RenderSystem
KORE.ConsoleSystem = src.Console
KORE.Prefabs = src.Prefabs
KORE.Physics = src.Physics
KORE.images = src.AssetsSystem.images
KORE.sounds = src.AssetsSystem.sounds
KORE.fonts = src.AssetsSystem.fonts
KORE.libs = {
    anim8 = require("libs/anim8"),
    bump = require("libs/bump"),
    camera = require("libs/hump/camera"),
    timer = require("libs/hump/timer"),
    vector = require("libs/hump/vector"),
    class = require("libs/hump/class"),
    gamestate = require("libs/hump/gamestate")
}
local cam
local debug = false

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
    WorldSystem.addtoworld(ECS.entities)
    ConsoleSystem:init({
        entities = ECS.entities,
        player = player,
        WorldSystem = WorldSystem,
        setDebug = function(value)
            debug = value
        end
    })
end

function KORE.update(dt)
    KORE.libs.timer.update(dt)
    PhysicsSystem.update(dt)
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