local BASE = "KORE."
local anim8 = require(BASE .. "libs.anim8")
local log = require(BASE .. "src.log")
local spritefolder
local spritepacksfolder
local worldpackfolder
local soundfolder
local fontfolder
local shaderfolder
local AssetsSystem = {}

AssetsSystem.images = {}
AssetsSystem.sounds = {}
AssetsSystem.fonts = {}
AssetsSystem.shaders = {}

function AssetsSystem.init(context)
    if context == nil then log.info("No passed path for assets folders, using default.") end
        spritefolder = context and context.spritefolder or "assets/sprites"
        spritepacksfolder = context and context.spritepacksfolder or "assets/spritepacks"
        worldpackfolder = context and context.worldpackfolder or "assets/world"
        soundfolder = context and context.soundfolder or "assets/sounds"
        fontfolder = context and context.fontfolder or "assets/fonts"
        shaderfolder = context and context.shaderfolder or "assets/shaders"
        log.info("Asset folders initialized")
end

function AssetsSystem.loadpack(packName, packtype)
    if packtype == "anim8anim" then
        if next(AssetsSystem.images) == nil then
            AssetsSystem.loadimages()
        end

        local pack = require(spritepacksfolder .. "/" .. packName)
        local sprite = {}

        for name, data in pairs(pack) do
            local imageKey = data.image and string.lower(data.image)
            local image = AssetsSystem.images[imageKey] or AssetsSystem.images[data.image]

            if not image then
                log.fail(
                "Missing image for " ..
                tostring(data.image) ..
                " while loading pack " ..
                tostring(packName)
            )
            end

            if data.type == "animation" then
                local grid = anim8.newGrid(
                    data.frameWidth,
                    data.frameHeight,
                    image:getWidth(),
                    image:getHeight()
                )

                sprite[name] = {
                    type = "animation",
                    image = image,
                    previousframe = 0,
                    animation = anim8.newAnimation(
                        grid(data.frames, data.row),
                        data.speed
                    )
                }

            elseif data.type == "image" then
                sprite[name] = {
                    type = "image",
                    image = image
                }
            end
        end

        return sprite
    elseif packtype == "world" then
        local map = require(worldpackfolder .. "/" .. packName)
        return map
    else
        log.fail("Unknown pack type: " .. tostring(packtype))
    end
end

function AssetsSystem.loadimages()
    if spritefolder then
        for key in pairs(AssetsSystem.images) do
            AssetsSystem.images[key] = nil
        end

        local files = love.filesystem.getDirectoryItems(spritefolder)
        local loaded = 0
        for _, filename in ipairs(files) do
            local key = string.lower(filename)
            local path = spritefolder .. "/" .. filename

            if love.filesystem.getInfo(path) and love.filesystem.getInfo(path).type == "file" then
                local image = love.graphics.newImage(path)

                if image then
                    AssetsSystem.images[key] = image
                    AssetsSystem.images[filename] = image
                    loaded = loaded + 1
                end
            else
                print("Could not load image: " .. path)
            end
        end
        log.info("Loaded " .. tostring(loaded) .. " image(s)")
        return AssetsSystem.images
    else
        log.info("Attempted to load images; spritefolder is not present to load images from.")
    end
end

function AssetsSystem.loadsounds()
    if soundfolder then
        for key in pairs(AssetsSystem.sounds) do
            AssetsSystem.sounds[key] = nil
        end

        local files = love.filesystem.getDirectoryItems(soundfolder)
        local loaded = 0

        for _, filename in ipairs(files) do
            local key = string.lower(filename)
            local path = soundfolder .. "/" .. filename

            if love.filesystem.getInfo(path) and love.filesystem.getInfo(path).type == "file" then
                local sound = love.audio.newSource(path)

                if sound then
                    AssetsSystem.sounds[key] = sound
                    AssetsSystem.sounds[filename] = sound
                    loaded = loaded + 1
                end
            else
                print("Could not load sound: " .. path)
            end
        end
        log.info("Loaded " .. tostring(loaded) .. " sound(s)")
        return AssetsSystem.sounds
    else
        log.warn("Attempted to load sounds; soundfolder is not present to load sounds from.")
    end
end

function AssetsSystem.loadfonts()
    if fontfolder then
        for key in pairs(AssetsSystem.fonts) do
            AssetsSystem.fonts[key] = nil
        end

        local files = love.filesystem.getDirectoryItems(fontfolder)
        local loaded = 0

        for _, filename in ipairs(files) do
            local key = string.lower(filename)
            local path = fontfolder .. "/" .. filename

            if love.filesystem.getInfo(path) and love.filesystem.getInfo(path).type == "file" then
                local font = love.graphics.newFont(path)

                if font then
                    AssetsSystem.fonts[key] = font
                    AssetsSystem.fonts[filename] = font
                    loaded = loaded + 1
                end
            else
                print("Could not load font: " .. path)
            end
        end
        log.info("Loaded " .. tostring(loaded) .. " font(s)")
        return AssetsSystem.fonts
    else
        log.warn("Attempted to load fonts; fontolder is not present to load fonts from.")
    end
end

function AssetsSystem.loadshaders()
    if shaderfolder then
        for key in pairs(AssetsSystem.shaders) do
            AssetsSystem.shaders[key] = nil
        end

        local files = love.filesystem.getDirectoryItems(shaderfolder)
        local loaded = 0

        for _, filename in ipairs(files) do
            local key = string.lower(filename)
            local path = shaderfolder .. "/" .. filename

            if love.filesystem.getInfo(path) and love.filesystem.getInfo(path).type == "file" then
                local shader = love.graphics.newShader(path)

                if shader then
                    AssetsSystem.shaders[key] = shader
                    AssetsSystem.shaders[filename] = shader
                    loaded = loaded + 1
                end
            else
                print("Could not load shader: " .. path)
            end
        end
        log.info("Loaded " .. tostring(loaded) .. " shader(s)")
        return AssetsSystem.shaders
    else
        log.warn("Attempted to load shader; shaderfolder is not present to load shaders from.")
    end
end

function AssetsSystem.reloadassets(assettype)
    log.info("== reloading assets ==")
    if assettype == nil then
        AssetsSystem.loadimages()
        AssetsSystem.loadsounds()
        AssetsSystem.loadfonts()
        AssetsSystem.loadshaders()
    elseif assettype == "images" then
        AssetsSystem.loadimages()
    elseif assettype == "sounds" then
        AssetsSystem.loadsounds()
    elseif assettype == "fonts" then
        AssetsSystem.loadfonts()
    elseif assettype == "shaders" then
        AssetsSystem.loadshaders()
    else
        log.warn("Unknown asset type requested for reload: " .. tostring(assettype))
    end
    log.info("== reloaded assets ==")
end

return AssetsSystem