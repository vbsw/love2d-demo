--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

require("state")
require("gfx")

function input_key_pressed(scancode, isrepeat)
    if not isrepeat then
        if scancode == "escape" then
            love.event.quit(0)
        elseif scancode == "f" then
            state.fullscreen = not state.fullscreen
            love.window.setFullscreen(state.fullscreen)
        elseif scancode == "j" then
            state.mipmap = not state.mipmap
        elseif scancode == "i" then
            state.info = not state.info
        elseif scancode == "a" then
            state.scale = state.scale / 2
        elseif scancode == "s" then
            state.scale = state.scale * 2
        elseif scancode == "r" then
            state.rotating = not state.rotating
        elseif scancode == "m" then
            state.moving = not state.moving
        elseif scancode == "c" then
            gfx_clear_chibis()
            state.chibis_count = 0
        end
    end
    if scancode == "1" then
        gfx_add_chibis(1)
        state.chibis_count = state.chibis_count + 1
    elseif scancode == "2" then
        gfx_add_chibis(10)
        state.chibis_count = state.chibis_count + 10
    elseif scancode == "3" then
        gfx_add_chibis(100)
        state.chibis_count = state.chibis_count + 100
    elseif scancode == "4" then
        gfx_add_chibis(1000)
        state.chibis_count = state.chibis_count + 1000
    elseif scancode == "5" then
        gfx_add_chibis(10000)
        state.chibis_count = state.chibis_count + 10000
    elseif scancode == "k" then
        if state.speed > 0 then
            state.speed = state.speed - 4
        end
    elseif scancode == "l" then
        state.speed = state.speed + 4
    end
end