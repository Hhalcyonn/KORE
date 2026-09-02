local KORE = {}
local src =  require("src/init")

local ECS = src.ECS
local AssetsSystem = src.AssetsSystem
local WorldSystem = src.WorldSystem
local RenderSystem = src.RenderSystem
local ConsoleSystem = src.Console
local Prefabs = src.Prefabs
local Utils = src.Utils
local Physics = src.Physics
local cam
local debug = false

function KORE.initAssetsPath(context)
    AssetsSystem.init(context)
end

function KORE.setCamera(camera)
    cam = camera
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

function love.update(dt)
    Physics.initializedt(dt)
    for _, entity in ipairs(ECS.entities) do
        ECS.update(dt, entity)
    end
    ConsoleSystem:update()
    WorldSystem.update(ECS.entities, dt)
    ECS.removeDeadEntities()
end

function KORE.drawinworld()
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
end

function KORE.drawonscreen()
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

return KORE