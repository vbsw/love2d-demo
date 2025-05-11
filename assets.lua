--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

assets = {
    widths = {512, 399, 400, 347, 418},
    heights = {443, 512, 512, 512, 512}
}

function assets_load()
    local images = {"assets/chibi0.png", "assets/chibi1.png", "assets/chibi2.png", "assets/chibi3.png", "assets/chibi4.png"}
    assets.img = love.graphics.newArrayImage(images)
    assets.img_mm = love.graphics.newArrayImage(images, {mipmaps = true, linear = true})
    local font = love.graphics.newFont(28)
    love.graphics.setFont(font)
end