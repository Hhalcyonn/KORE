local BASE = "KORE."

local KORE = {}
local config = require(BASE .. "config")

KORE.ECS = require(BASE .. "src.EntityComponentSystem")
KORE.AssetsSystem = require(BASE .. "src.AssetsSystem")
KORE.WorldSystem = require(BASE .. "src.WorldSystem")
KORE.RenderSystem = require(BASE .. "src.RenderSystem")
KORE.ConsoleSystem = require(BASE .. "src.Console")
KORE.Physics = require(BASE .. "src.PhysicsSystem")
KORE.Log = require(BASE .. "src.log")

KORE.images = KORE.AssetsSystem.images
KORE.sounds = KORE.AssetsSystem.sounds
KORE.fonts = KORE.AssetsSystem.fonts
KORE.shders = KORE.AssetsSystem.shaders

KORE.libs = {
    anim8 = require(BASE .. "libs.anim8"),
    bump = require(BASE .. "libs.bump"),
    camera = require(BASE .. "libs.hump.camera"),
    timer = require(BASE .. "libs.hump.timer"),
    vector = require(BASE .. "libs.hump.vector"),
    class = require(BASE .. "libs.hump.class"),
    gamestate = require(BASE .. "libs.hump.gamestate"),
}

local ECS = KORE.ECS
local AssetsSystem = KORE.AssetsSystem
local WorldSystem = KORE.WorldSystem
local RenderSystem = KORE.RenderSystem
local ConsoleSystem = KORE.ConsoleSystem
local PhysicsSystem = KORE.Physics

local cam
KORE.entities = ECS.entities

function KORE.setDebug(value)
    if type(value) == "boolean" then
        config.debug = value
    else
        log.debug("Attempted to call setDebug; value is not a boolean or is nil.")
    end
end

function KORE.getDebug()
    return config.debug
end

function KORE.reloadassets(assettype)
    AssetsSystem.reloadassets(assettype)
end

function KORE.setCamera()
    cam = KORE.libs.camera()
    KORE.Log.info("Setted camera.")
    return cam
end

function KORE.unsetCamera()
    cam = nil
    KORE.Log.info("Unsetted camera.")
    return nil
end

function KORE.getCamera()
    return cam
end

function KORE.load()
    math.randomseed(os.time())
    AssetsSystem.reloadassets()

    ConsoleSystem:init({
        entities = ECS.entities,
        WorldSystem = WorldSystem,
        setDebug = KORE.setDebug
    })

    if WorldSystem.world then
        for _, entity in pairs(ECS.entities) do
            WorldSystem.addtoworld(entity)
        end
    end
end

function KORE.update(dt)
    KORE.libs.timer.update(dt)
    PhysicsSystem.update(ECS.entities, dt)
    for _, entity in pairs(ECS.entities) do ECS.update(dt, entity) end
    ConsoleSystem:update()
    ECS.removeDeadEntities()
    WorldSystem.update(ECS.entities, dt)
end

function KORE.draw()
    if cam then
        cam:attach()
    end

    RenderSystem:render(ECS.entities)

    if config.debug then
        RenderSystem:drawdebuginworld(ECS.entities)
    end

    if cam then
        cam:detach()
    end

    RenderSystem:draw()

    if config.debug then
        RenderSystem:drawdebugonscreen(ECS.entities)
    end

    ConsoleSystem:draw()
end

function KORE.keypressed(key)
    ConsoleSystem:keypressed(key)

    for _, entity in pairs(ECS.entities) do
        ECS.onKeyPressed(key, entity)
    end
end

function KORE.keyreleased(key)
    for _, entity in pairs(ECS.entities) do
        ECS.onKeyReleased(key, entity)
    end
end

function KORE.mousepressed(x, y, button)
    for _, entity in pairs(ECS.entities) do
        ECS.onMousePressed(x, y, button, entity)
    end
end

function KORE.textinput(text)
    ConsoleSystem:textinput(text)
end

function KORE.AddCommand(name, callback)
    ConsoleSystem:addCommand(name, callback)
end

function KORE.spawnEntity(data)
    local entity = ECS.createentity(data)

    ECS.register(entity)

    return entity
end

function KORE.loadworldpack(worldpack)
    if not worldpack then
        return
    end

    for _, entitydata in pairs(worldpack) do
        ECS.register(ECS.createentity(entitydata))
    end
end

function KORE.clearEntities()
    ECS.clearAllEntities()
end

function KORE.getEntity(by, value)
    return ECS.getEntityByIdentity(by, value)
end

function KORE.initworld(cellsize, worldpack)
    WorldSystem.initworld(cellsize, worldpack)
end

function KORE.deleteworld()
    WorldSystem.deletworld()
end

function KORE.getworld()
    return WorldSystem.world
end

function KORE.setWorldPhysics(name, value)
    if name == "gravity" then
        PhysicsSystem.worldgravity = value
    elseif name == "drag" then
        PhysicsSystem.worlddrag = value
    elseif name == "friction" then
        PhysicsSystem.worldfriction = value
    end
end

function KORE.setWorldGravity(value)
    PhysicsSystem:setWorldGravity(value)
end

function KORE.setWorldDrag(value)
    PhysicsSystem:setWorldDrag(value)
end

function KORE.setWorldFriction(value)
    PhysicsSystem:setWorldFriction(value)
end

function KORE.enablePhysics(bool)
    PhysicsSystem:enablePhysics(bool)
end

function KORE.getWorldPhysics()
    local gravity, drag, friction = PhysicsSystem.worldgravity, PhysicsSystem.worlddrag, PhysicsSystem.worldfriction
    return gravity, drag, friction
end

function KORE.resizedimension(width, height)
    RenderSystem.resize(width, height)
end

function KORE.setLayerShader(layer, shader)
    RenderSystem.setShader(layer, shader)
end

function KORE.clearLayerShader(layer)
    RenderSystem.clearShader(layer)
end

function KORE.clearAllShaders()
    RenderSystem.clearAllShaders()
end

function KORE.getShader(layer)
    RenderSystem.getShader(layer)
end

function KORE.setScreenDebug(callback)
    RenderSystem.screendebug(callback)
end

function KORE.setWorldDebug(callback)
    RenderSystem.worlddebug(callback)
end

function KORE.logdebug(msg)
    KORE.Log.debug(msg)
end

function KORE.loginfo(msg)
    KORE.Log.info(msg)
end

function KORE.logwarn(msg)
    KORE.Log.warn(msg)
end

function KORE.logerror(msg)
    KORE.Log.error(msg)
end

function KORE.logfail(msg, level)
    KORE.Log.fail(msg, level)
end

return KORE