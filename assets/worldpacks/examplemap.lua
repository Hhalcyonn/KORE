local ECS = require("src/EntityComponentSystem")

return {
    ECS.createentity({
        x = -5000,
        y = 500,
        drawdata = {
            spritewidth = 10000,
            spriteheight = 50,
            layer = "world"
        }
        collider = {
            height = 50,
            width = 10000
        }
    }),
    ECS.createentity({
        x = -5000,
        y = 500,
        drawdata = {
            spritewidth = 50,
            spriteheight = 400,
            layer = "world"
        }
        collider = {
            height = 400,
            width = 50
        }
    })
}