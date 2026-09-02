-- L2D-BootlegSet/src/init.lua
-- Central entry point for the L2D-BootlegSet framework
-- This file exports all the main modules for easy access

return {
    ECS = require("src/EntityComponentSystem"),
    AssetsSystem = require("src/AssetsSystem"),
    WorldSystem = require("src/WorldComponentSystem"),
    RenderSystem = require("src/RenderComponentSystem"),
    Console = require("src/Console"),
    Physics = require("src/PhysicsComponentSystem"),
    Prefabs = require("src/Prefabs"),
    Utils = require("src/utils"),
}
