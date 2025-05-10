--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

assets = {
    chibi = {},
    chibi_mm = {},
    widths = {512, 399, 400, 347, 418},
    heights = {443, 512, 512, 512, 512}
}

function assets_load()
    assets.chibi[1] = love.graphics.newImage("assets/chibi0.png")
    assets.chibi[2] = love.graphics.newImage("assets/chibi1.png")
    assets.chibi[3] = love.graphics.newImage("assets/chibi2.png")
    assets.chibi[4] = love.graphics.newImage("assets/chibi3.png")
    assets.chibi[5] = love.graphics.newImage("assets/chibi4.png")
    assets.chibi_mm[1] = love.graphics.newImage("assets/chibi0.png", {mipmaps = true, linear = true})
    assets.chibi_mm[2] = love.graphics.newImage("assets/chibi1.png", {mipmaps = true, linear = true})
    assets.chibi_mm[3] = love.graphics.newImage("assets/chibi2.png", {mipmaps = true, linear = true})
    assets.chibi_mm[4] = love.graphics.newImage("assets/chibi3.png", {mipmaps = true, linear = true})
    assets.chibi_mm[5] = love.graphics.newImage("assets/chibi4.png", {mipmaps = true, linear = true})
    local font = love.graphics.newFont(30)
    love.graphics.setFont(font)
end