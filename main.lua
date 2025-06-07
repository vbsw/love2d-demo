--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

local clock = os.clock

local assets = {
    widths = {512, 399, 400, 347, 418},
    heights = {443, 512, 512, 512, 512}
}

local state = {
	profiling = 0,
	prof_count = 0,
    fullscreen = false,
    mipmap = false,
    mipmap_reset = false,
    chibis_count = 0,
    scale = 0.125,
    rotating = false,
    moving = false,
    speed = 100,
    info = true,
    info_alpha = 1,
	vsync = false,
	batch = false,
	batch_reset = false,
	ups = 0, ups_count = 0, ups_time = 0.0,
	fps = 0, fps_count = 0, fps_time = 0.0
}

local padding = 3
local client_w = 1024
local client_h = 768
local chibis = {}
local spriteBatch = {}

function love.load()
    -- https://github.com/2dengine/profile.lua
    love.profiler = require("libs/profile")
    love.keyboard.setKeyRepeat(true)
    local images = {"assets/chibi0.png", "assets/chibi1.png", "assets/chibi2.png", "assets/chibi3.png", "assets/chibi4.png"}
    assets.img = love.graphics.newArrayImage(images)
    assets.img_mm = love.graphics.newArrayImage(images, {mipmaps = true, linear = true})
    local font = love.graphics.newFont(28)
    love.graphics.setFont(font)
	spriteBatch = love.graphics.newSpriteBatch(assets.img, 100000)
end

function love.keypressed(key, scancode, isrepeat)
    if not isrepeat then
        if scancode == "escape" then
            love.event.quit(0)
        elseif scancode == "p" then
			toggle_profiler()
        elseif scancode == "t" then
			if state.profiling == 2 then
				love.report = love.profiler.report(20)
				love.profiler.reset()
				print(love.report)
			end
        elseif scancode == "f" then
            state.fullscreen = not state.fullscreen
            love.window.setFullscreen(state.fullscreen)
        elseif scancode == "j" then
            state.mipmap = not state.mipmap
			state.mipmap_reset = true
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
        elseif scancode == "v" then
			state.vsync = love.window.getVSync() == 0
            love.window.setVSync(state.vsync)
        elseif scancode == "c" then
            clear_chibis()
            state.chibis_count = 0
        elseif scancode == "b" then
            state.batch = not state.batch
			state.batch_reset = true
        end
    end
    if scancode == "1" then
        add_chibis(1)
        state.chibis_count = state.chibis_count + 1
    elseif scancode == "2" then
        add_chibis(10)
        state.chibis_count = state.chibis_count + 10
    elseif scancode == "3" then
        add_chibis(100)
        state.chibis_count = state.chibis_count + 100
    elseif scancode == "4" then
        add_chibis(1000)
        state.chibis_count = state.chibis_count + 1000
    elseif scancode == "5" then
        add_chibis(10000)
        state.chibis_count = state.chibis_count + 10000
    elseif scancode == "k" then
        if state.speed > 0 then
            state.speed = state.speed - 4
        end
    elseif scancode == "l" then
        state.speed = state.speed + 4
    end
end

function love.resize(w, h)
    client_w, client_h = w, h
end

function love.update(dt)
	local time_curr = clock() * 1000.0
	if state.profiling == 1 then
		state.prof_count = state.prof_count + 1
		if state.prof_count == 10 then
			love.profiler.reset()
		elseif state.prof_count >= 110 then
			love.report = love.profiler.report(20)
			love.profiler.stop()
			print(love.report)
			state.profiling = 0
		end
	end
    if dt < 1.0 then
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
		if state.batch and (state.rotating or state.moving or state.batch_reset) then
			state.batch_reset = false
            for i, chibi in ipairs(chibis) do
				spriteBatch:setLayer(i, chibi.idx, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
            end
		end
        update_alpha(dt)
    end
	update_ups(clock() * 1000.0 - time_curr)
end

function love.draw()
	local time_curr = clock() * 1000.0
    local scale = state.scale
    local info_alpha = state.info_alpha
    love.graphics.setColor(1, 1, 1, 1)
	if state.mipmap_reset then
		if state.mipmap then
			spriteBatch:setTexture(assets.img_mm)
		else
			spriteBatch:setTexture(assets.img)
		end
		state.mipmap_reset = false
	end
	if state.batch then
		love.graphics.draw(spriteBatch)
	else
		if state.mipmap then
			local img_mm = assets.img_mm
			for i, chibi in ipairs(chibis) do
				love.graphics.drawLayer(img_mm, chibi.idx, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
			end
		else
			local img = assets.img
			for i, chibi in ipairs(chibis) do
				love.graphics.drawLayer(img, chibi.idx, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
			end
		end
	end
    if info_alpha > 0 then
        local xl = client_w/2-230
        local xr = client_w/2+230+40
		local movementDesc = get_desc("movement", state.moving, true)
		local rotationDesc = get_desc("rotation", state.rotating, true)
		local mipmapDesc = get_desc("MipMap", state.mipmap, true)
		local fullscreenDesc = get_desc("fullscreen", state.fullscreen, true)
		local infoDesc = get_desc("info", state.info, true)
		local vsyncDesc = get_desc("v-sync", state.vsync, true)
		local batchingDesc = get_desc("batching", state.batch, false)
        love.graphics.setColor(0, 0, 0, 0.8*info_alpha)
        love.graphics.polygon("fill", xl,80, xr,80, xr,700, xl,700)
        love.graphics.setColor(0.9, 1, 0.9, 0.9*info_alpha)
		love.graphics.print("chibis\n" .. #chibis, xl+20, 100)
        love.graphics.print("FPS\n" .. love.timer.getFPS(), client_w/2+20-100, 100)
        love.graphics.print("FPS*\n" .. state.fps, client_w/2+30, 100)
        love.graphics.print("UPS*\n" .. state.ups, client_w/2+140, 100)
        love.graphics.setColor(1, 1, 1, 0.5*info_alpha)
        love.graphics.print("controls", client_w/2+20-100, 200)
        love.graphics.printf("1 - 5\nc\nm\nr\nj\na, s\nk,  l\nf\ni\nv\nb", (client_w)/2-120-100, 260, 100, "right")
        love.graphics.print("spawn chibis\n" ..
        "clear screen\n" ..
        movementDesc ..
        rotationDesc ..
        mipmapDesc ..
        "de-/increment size\n" ..
        "de-/increment speed\n" ..
        fullscreenDesc ..
        infoDesc ..
        vsyncDesc ..
        batchingDesc, client_w/2+20-100, 260)
    end
	love.graphics.flushBatch()
	update_fps(clock() * 1000.0 - time_curr)
end

function update_alpha(dt)
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

function clear_chibis()
    for i=#chibis, 0, -1 do
        chibis[i] = nil
    end
	spriteBatch:clear()
end

function add_chibis(count)
    local scale = state.scale
    for i=1, count do
        local index = math.random(1, 5)
        local img_width = assets.widths[index]
        local img_height = assets.heights[index]
        local img_quad = love.graphics.newQuad(0, 0, img_width, img_height, 512, 512)
        local movx = math.random()-0.50
        local movy = math.random()-0.50
        local rot_speed = math.random()*0.125-0.0625
        local rotx, roty = img_width/2, img_height/2
        if movx >= 0 then movx = movx + 0.15 else movx = movx - 0.15 end
        if movy >= 0 then movy = movy + 0.15 else movy = movy - 0.15 end
		local chibi = {
            idx = index,
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
        }
        table.insert(chibis, chibi)
		spriteBatch:addLayer(chibi.idx, chibi.quad, chibi.x, chibi.y, chibi.r*180/math.pi, scale, scale, chibi.rx, chibi.ry)
    end
end

function get_desc(desc, enabled, nl)
	local result = desc
	if nl then
		if enabled then
			result = result .. " (ON/off)\n"
		else
			result = result .. " (on/OFF)\n"
		end
	else
		if enabled then
			result = result .. " (ON/off)"
		else
			result = result .. " (on/OFF)"
		end
	end
	return result
end

function toggle_profiler()
	if state.profiling == 0 then
		if love.keyboard.isScancodeDown("lshift") then
			state.profiling = 2
		else
			state.profiling = 1
			state.prof_count = 0
		end
		love.profiler.start()
	-- (state.profiling == 1) is handled automatically
	elseif state.profiling == 2 then
		love.profiler.stop()
		state.profiling = 0
	end
end

function update_ups(delta)
	state.ups_time = state.ups_time + delta
	state.ups_count = state.ups_count + 1
	if state.ups_time > 1000.0 or state.ups_count == 100 then
		local avarage_time_per_update = state.ups_time / state.ups_count
		if avarage_time_per_update > 0 then
			state.ups = math.floor(1000.0 / avarage_time_per_update)
			state.ups_time = 0
		end
		if avarage_time_per_update == 0 or state.ups > 9999 then
			state.ups = 9999
		end
		state.ups_count = 0
	end
end

function update_fps(delta)
	state.fps_time = state.fps_time + delta
	state.fps_count = state.fps_count + 1
	if state.fps_time > 1000.0 or state.fps_count == 100 then
		local avarage_time_per_frame = state.fps_time / state.fps_count
		if avarage_time_per_frame > 0 then
			state.fps = math.floor(1000.0 / avarage_time_per_frame)
			state.fps_time = 0
		end
		if avarage_time_per_frame == 0 or state.fps > 9999 then
			state.fps = 9999
		end
		state.fps_count = 0
	end
end
