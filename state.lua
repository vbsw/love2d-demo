--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

state = {
    fullscreen = false,
    mipmap = false,
    chibis_count = 0,
    scale = 0.125,
    rotating = false,
    moving = false,
    speed = 100,
    info = true,
    info_alpha = 1
}

function state_update_alpha(dt)
    if state.info then
        if state.info_alpha < 1 then
            state.info_alpha = state.info_alpha + 8*dt
            if state.info_alpha > 1 then
                state.info_alpha = 1
            end
        end
    else
        if state.info_alpha > 0 then
            state.info_alpha = state.info_alpha - 8*dt
            if state.info_alpha < 0 then
                state.info_alpha = 0
            end
        end
    end
end
