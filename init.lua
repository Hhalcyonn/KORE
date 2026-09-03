local KORE = {}
local src =  require("src/init")

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

function KORE.load()
    math.randomseed(os.time())
    AssetsSystem.loadimages()
    WorldSystem.initworld()
    WorldSystem.addtoworld(ECS.entities)
    ConsoleSystem:init({
        entities = ECS.entities,
        subtypebatch = ECS.subtypebatch,
        typebatch = ECS.typebatch,
        player = player,
        WorldSystem = WorldSystem,
        setDebug = function(value)
            debug = value
        end
    })
end

function KORE.update(dt)
    PhysicsSystem.initializedt(dt)
    for _, entity in ipairs(ECS.entities) do
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
    for _, entity in ipairs(ECS.entities) do
        ECS.keypressfunction(key, entity)
    end
end

function KORE.keyreleased(key)
    ConsoleSystem:keyreleased(key)
    for _, entity in ipairs(ECS.entities) do
        ECS.keyreleasefunction(key, entity)
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

function KORE.spawnStructure(data)
    local e = ECS.createstructure(data)
    ECS.register(e)
    return e
end

function KORE.spawnPlayer(data)
    local e = ECS.createplayer(data)
    ECS.register(e)
    return e
end

function KORE.spawnNPC(data)
    local e = ECS.createnpc(data)
    ECS.register(e)
    return e
end

function KORE.spawnObject(data)
    local e = ECS.createobject(data)
    ECS.register(e)
    return e
end

function KORE.spawnParticle(data)
    local e = ECS.createparticle(data)
    ECS.register(e)
    return e
end

return KORE