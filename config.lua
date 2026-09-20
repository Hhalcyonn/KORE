return {

    Debug = false,

    AssetsSystem = {
        spritefolder = "assets/sprites",
        spritepacksfolder = "assets/spritepacks",
        worldpackfolder = "assets/worldpack",
        soundfolder = "assets/sounds",
        fontfolder = "assets/fonts",
        shaderfolder = "assets/shaders",
    },

    Console = {
        open_key = "`",
        close_key = "escape",
        execute_key = "return"
    },

    PhysicsSystem = {
        physics_mode = "advanced", -- simple/advanced,
        worlddrag = 0.5, -- only advanced mode use world physics
        worldfriction = 10,
        worldgravity = 400
    },

    RenderSystem = {

    },

    Log = {
        maxHistory = 100,
        enablePrint = true,
        enableFile = true,
        filename = "KORE/log.txt"
    }
}