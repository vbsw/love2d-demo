function love.conf(t)
    t.window.vsync = 0
    t.window.title = "LÖVE Demo"
    t.window.width = 1024
    t.window.height = 768
    t.window.resizable = true
    t.modules.audio = false
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.system = false
    t.modules.timer = true
    t.modules.window = true
    t.modules.thread = false
end