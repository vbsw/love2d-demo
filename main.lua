--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

require("assets")
require("input")
require("gfx")

function love.load()
    love.keyboard.setKeyRepeat(true)
    assets_load()
end

function love.keypressed(key, scancode, isrepeat)
    input_key_pressed(scancode, isrepeat)
end

function love.resize(w, h)
    gfx_update_client_size(w, h)
end

function love.update(dt)
    gfx_update(dt)
end

function love.draw()
    gfx_draw()
end