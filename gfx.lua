--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

require("state")
require("assets")

local padding = 3
local client_w = 1024
local client_h = 768
local chibis = {}

function gfx_update_client_size(w, h)
    client_w, client_h = w, h
end

function gfx_clear_chibis()
    for i=#chibis, 0, -1 do
        chibis[i] = nil
    end
end

function gfx_add_chibis(count)
    local scale = state.scale
    chibi = {}
    for i=1, count do
        local index = math.random(1, 5)
        local img_width = assets.widths[index]
        local img_height = assets.heights[index]
        local img_quad = love.graphics.newQuad(0, 0, img_width, img_height, assets.chibi[index])
        local movx = math.random()-0.50
        local movy = math.random()-0.50
        local rot_speed = math.random()*0.125-0.0625
        local rotx, roty = img_width/2, img_height/2
        if movx >= 0 then movx = movx + 0.15 else movx = movx - 0.15 end
        if movy >= 0 then movy = movy + 0.15 else movy = movy - 0.15 end
        table.insert(chibis, {
            img = assets.chibi[index],
            img_mm = assets.chibi_mm[index],
            quad = img_quad,
            width = img_width,
            height = img_height,
            x = math.random(img_width*scale/2+padding, client_w-img_width*scale/2-padding),
            y = math.random(img_height*scale/2+padding, client_h-img_height*scale/2-padding),
            movx = movx,
            movy = movy,
            r = 0,
            rs = rot_speed,
            rx = rotx,
            ry = roty
        })
    end
end

function gfx_update(dt)
    if dt < 0.1 then
        local scale = state.scale
        if state.rotating then
            for i, chibi in ipairs(chibis) do
                chibi.r = chibi.r + chibi.rs*dt
                if chibi.r > 360 then
                    chibi.r = chibi.r - 360
                elseif chibi.r < -360 then
                    chibi.r = chibi.r + 360
                end
            end
        end
        if state.moving then
            local speed = state.speed
            for i, chibi in ipairs(chibis) do
                if (chibi.x - chibi.width*scale/2 < padding and chibi.movx < 0) or (chibi.x > client_w - (chibi.width*scale/2+padding) and chibi.movx > 0) then
                    chibi.movx = -1 * chibi.movx
                end
                if (chibi.y - chibi.height*scale/2 < padding and chibi.movy < 0) or (chibi.y > client_h - (chibi.height*scale/2+padding) and chibi.movy > 0) then
                    chibi.movy = -1 * chibi.movy
                end
                chibi.x = chibi.x + chibi.movx*dt*speed
                chibi.y = chibi.y + chibi.movy*dt*speed
            end
        end
        state_update_alpha(dt)
    end
end

function gfx_draw()
    local scale = state.scale
    local info_alpha = state.info_alpha
    love.graphics.setColor(1, 1, 1, 1)
    if state.mipmap then
        for i, chibi in ipairs(chibis) do
            love.graphics.draw(chibi.img_mm, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
        end
    else
        for i, chibi in ipairs(chibis) do
            love.graphics.draw(chibi.img, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
        end
    end
    if info_alpha > 0 then
        local xl = client_w/2-230
        local xr = client_w/2+230+40
        love.graphics.setColor(0, 0, 0, 0.8*info_alpha)
        love.graphics.polygon("fill", xl,80, xr,80, xr,700, xl,700)
        love.graphics.setColor(1, 1, 1, 0.5*info_alpha)
        love.graphics.print("controls", client_w/2+20-100, 100)
        love.graphics.printf("1 - 5\nc\nm\nr\nj\na, s\nk,  l\nf\ni", (client_w)/2-120-100, 160, 100, "right")
        love.graphics.print("spawn chibis\n" ..
        "clear screen\n" ..
        "movement (on/off)\n" ..
        "rotation (on/off)\n" ..
        "MipMap (on/off)\n" ..
        "de-/increment size\n" ..
        "de-/increment speed\n" ..
        "fullscreen (on/off)\n" ..
        "info (on/off)", client_w/2+20-100, 160)
        love.graphics.setColor(0.9, 1, 0.9, 0.9*info_alpha)
        love.graphics.print("chibis\n" .. #chibis, client_w/2+20-100, 580)
        love.graphics.print("FPS\n" .. love.timer.getFPS(), client_w/2+20-100+200, 580)
    end
end
