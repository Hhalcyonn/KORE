return {
    idle = {
        type = "animation",
        image = "whiteidle.png",
        frameWidth = 94,
        frameHeight = 94,
        frames = "1-3",
        row = 1,
        speed = 0.15
    },
    
    jumping = {
        type = "image",
        image = "whitejump.png",
        frameWidth = 94,
        frameHeight = 94
    },

    sliding = {
        type = "image",
        image = "whiteslide.png",
        frameWidth = 94,
        frameHeight = 94
    },

    running = {
        type = "animation",
        image = "whiterun.png",
        frameWidth = 94,
        frameHeight = 94,
        frames = "1-6",
        row = 1,
        speed = 0.12
    },

    m1 = {
        type = "animation",
        image = "whitepunch1.png",
        frameWidth = 94,
        frameHeight = 94,
        frames = "1-8",
        row = 1,
        speed = {0.07, 0.07, 0.1, 0.07, 0.07, 0.4, 0.15, 1}
    },

    m2 = {
        type = "animation",
        image = "whitekick2.png",
        frameWidth = 94,
        frameHeight = 94,
        frames = "1-10",
        row = 1,
        speed = {0.07, 0.07, 0.07, 0.80, 0.70, 0.4, 0.15, 0.15, 0.07, 1}
    }
}