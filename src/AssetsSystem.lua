local anim8 = require("libs/anim8")
local spritefolder
local spritepacksfolder
local worldpackfolder
local soundfolder
local fontfolder
local AssetsSystem = {}

AssetsSystem.images = {}

function AssetsSystem.init(context)
    spritefolder = context.spritefolder or "assets/sprites"
    spritepacksfolder = context.spritepacksfolder or "assets/spritepacks"
    worldpackfolder = context.worldpackfolder or "assets/world"
    soundfolder = context.soundfolder or "assets/sounds"
    fontfolder = context.fontfolder or "assets/fonts"
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
                error("Missing image for " .. tostring(data.image) .. " while loading pack " .. packName)
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
        error("Unknown pack type: " .. tostring(packtype))
    end
end

function AssetsSystem.loadimages()
    AssetsSystem.images = {}
    local files = love.filesystem.getDirectoryItems(spritefolder)

    for _, filename in ipairs(files) do
        local key = string.lower(filename)
        local path = spritefolder .. "/" .. filename

        if love.filesystem.getInfo(path) and love.filesystem.getInfo(path).type == "file" then
            local image = love.graphics.newImage(path)
            if image then
                AssetsSystem.images[key] = image
                AssetsSystem.images[filename] = image
            end
        else
            print("Could not load image: " .. path)
        end
    end

    return AssetsSystem.images
end

return AssetsSystem