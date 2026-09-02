local ECS = require("src/EntityComponentSystem")

return {
    ECS.createstructure({
        x = -5000,
        y = 500,
        width = 10000,
        height = 50
    }),
    ECS.createstructure({
        x = 0,
        y = 0,
        width = 50,
        height = 400
    })
}