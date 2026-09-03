-- KORE/src/init.lua
-- Central entry point for the KORE framework
-- This file exports all the main modules for easy access

return {
    ECS = require("src/EntityComponentSystem"),
    AssetsSystem = require("src/AssetsSystem"),
    WorldSystem = require("src/WorldSystem"),
    RenderSystem = require("src/RenderSystem"),
    Console = require("src/Console"),
    Physics = require("src/PhysicsSystem"),
    Prefabs = require("src/Prefabs"),
}
