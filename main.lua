--		  Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--	 (See accompanying file LICENSE or copy at
--		http://www.boost.org/LICENSE_1_0.txt)

require("buffer")

local clock = os.clock

local threads_count = 8
local padding = 3

local assets = {
	widths = {512, 399, 400, 347, 418},
	heights = {443, 512, 512, 512, 512},
	quads = {},
}

local state = {
	profiling = 0,
	prof_count = 0,
	fullscreen = false,
	mipmap = false,
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
	fps = 0, fps_count = 0, fps_time = 0.0,
	threaded = false,
}

local client_w = 1024
local client_h = 768
local chibis, threads, channels_cmd, channels_rsp = {}, {}, {}, {}

local spriteBatch, font_big, font_small

function love.load()
	-- output to console without delay
	io.stdout:setvbuf('no')
	-- https://github.com/2dengine/profile.lua
	love.profiler = require("libs.profile")
	love.keyboard.setKeyRepeat(true)
	for i, width in ipairs(assets.widths) do
		local hight = assets.heights[i]
		assets.quads[i] = love.graphics.newQuad(0, 0, width, hight, 512, 512)
	end
	local images = {"assets/chibi0.png", "assets/chibi1.png", "assets/chibi2.png", "assets/chibi3.png", "assets/chibi4.png"}
	assets.img = love.graphics.newArrayImage(images)
	assets.img_mm = love.graphics.newArrayImage(images, {mipmaps = true, linear = true})
	font_big = love.graphics.newFont(28)
	font_small = love.graphics.newFont(10)
	spriteBatch = love.graphics.newSpriteBatch(assets.img, 100000)
	for i = 1, threads_count do
		threads[i] = love.thread.newThread("thread.lua")
		channels_cmd[i] = love.thread.newChannel()
		channels_rsp[i] = love.thread.newChannel()
		chibis[i] = {offset = 0, n = 0}
	end
	for i = 1, threads_count do
		if i < threads_count then
			threads[i]:start(threads_count, channels_cmd[i], channels_rsp[i], channels_cmd[i+1], i)
		else
			threads[i]:start(threads_count, channels_cmd[i], channels_rsp[i], channels_rsp[i], i)
		end
	end
end

function love.keypressed(key, scancode, isrepeat)
	if not isrepeat then
		if scancode == "escape" then
			quit_app()
		elseif scancode == "p" then
			toggle_profiler()
		elseif scancode == "t" then
			toggle_threaded()
		elseif scancode == "o" then
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
			if state.mipmap then
				spriteBatch:setTexture(assets.img_mm)
			else
				spriteBatch:setTexture(assets.img)
			end
			if state.threaded then
				channels_cmd[1]:push({cmd = "batch", spriteBatch = spriteBatch})
			end
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
			state.chibis_count = 0
			spriteBatch:clear()
			for i = 1, threads_count do
				chibis[i].offset, chibis[i].n = 0, 0
			end
			if state.threaded then
				for i = 1, threads_count do
					channels_cmd[i]:push({cmd = "clear"})
				end
				clear_channels_rsp()
				if state.batch then
					channels_cmd[1]:push({cmd = "batch", spriteBatch = spriteBatch})
				end
				send_update(0)
			end
		elseif scancode == "b" then
			toggle_batch()
		elseif scancode == "h" then
			print("hi")
		end
	end
	if scancode == "1" then
		add_chibis(1)
	elseif scancode == "2" then
		add_chibis(10)
	elseif scancode == "3" then
		add_chibis(100)
	elseif scancode == "4" then
		add_chibis(1000)
	elseif scancode == "5" then
		add_chibis(10000)
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

function threaded_update(dt, updateBatch)
	if state.batch then
		local data = channels_rsp[threads_count]:demand()
		spriteBatch = data.spriteBatch
	else
		for i = 1, threads_count do
			local data = channels_rsp[i]:demand()
			chibis[i] = data.chibis
		end
	end
	send_update(dt)
end

function love.update(dt)
	local time_curr = clock() * 1000.0
	update_profiling()
	if dt < 1.0 then
		local scale = state.scale
		local updateBatch = state.batch and (state.rotating or state.moving or state.batch_reset)
		state.batch_reset = false
		if state.threaded then
			-- call separate for benchmark purpose
			threaded_update(dt, updateBatch)
		else
			if state.rotating then
				for i = 1, threads_count do
					local chibs = chibis[i]
					for j = 1, chibs.n, 10 do
						local r_degrees = chibs[j+5] + chibs[j+7]*dt -- r=r*rot_speed*dt
						if r_degrees > 360 then
							r_degrees = r_degrees - 360
						elseif r_degrees < -360 then
							r_degrees = r_degrees + 360
						end
						chibs[j+5] = r_degrees
						chibs[j+6] = math.rad(r_degrees)
					end
				end
			end
			if state.moving then
				local widths, heights = assets.widths, assets.heights
				local speed = state.speed
				for i = 1, threads_count do
					local chibs = chibis[i]
					for j = 1, chibs.n, 10 do
						local index, x, y, movx, movy = chibs[j], chibs[j+1], chibs[j+2], chibs[j+3], chibs[j+4]
						local width, height = widths[index], heights[index]
						if (x - width*scale/2 < padding and movx < 0) or (x > client_w - (width*scale/2+padding) and movx > 0) then
							movx = -1 * movx
						end
						if (y - height*scale/2 < padding and movy < 0) or (y > client_h - (height*scale/2+padding) and movy > 0) then
							movy = -1 * movy
						end
						chibs[j+1], chibs[j+3] = x + movx*dt*speed, movx
						chibs[j+2], chibs[j+4] = y + movy*dt*speed, movy
					end
				end
			end
			if updateBatch and spriteBatch then
				local quads, chibiIdx = assets.quads, 0
				for i = 1, threads_count do
					local chibs = chibis[i]
					for j = 1, chibs.n, 10 do
						local index, x, y, radian, rx, ry = chibs[j], chibs[j+1], chibs[j+2], chibs[j+6], chibs[j+8], chibs[j+9]
						chibiIdx = chibiIdx + 1
						spriteBatch:setLayer(chibiIdx, index, quads[index], x, y, radian, scale, scale, rx, ry)
					end
				end
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
	if state.batch then
		if spriteBatch ~= nil then
			love.graphics.draw(spriteBatch)
		end
	else
		local img
		local quads = assets.quads
		if state.mipmap then
			img = assets.img_mm
		else
			img = assets.img
		end
		for i = 1, threads_count do
			local chibs = chibis[i]
			for j = 1, chibs.n, 10 do
				local index, x, y, radian, rx, ry = chibs[j], chibs[j+1], chibs[j+2], chibs[j+6], chibs[j+8], chibs[j+9]
				love.graphics.drawLayer(img, index, quads[index], x, y, radian, scale, scale, rx, ry)
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
		love.graphics.setFont(font_big)
		love.graphics.setColor(0.9, 1, 0.9, 0.9*info_alpha)
		love.graphics.print("chibis\n" .. state.chibis_count, xl+20, 100)
		love.graphics.print("FPS\n" .. love.timer.getFPS(), client_w/2+20-100, 100)
		love.graphics.print("FPS*\n" .. state.fps, client_w/2+30, 100)
		love.graphics.print("UPS*\n" .. state.ups, client_w/2+140, 100)
		love.graphics.setColor(1, 1, 1, 0.5*info_alpha)
		love.graphics.print("controls", client_w/2+20-100, 190)
		love.graphics.printf("1 - 5\nc\nm\nr\nj\na, s\nk,  l\nf\ni\nv\nb", (client_w)/2-120-100, 240, 100, "right")
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
		batchingDesc, client_w/2+20-100, 240)
		love.graphics.setFont(font_small)
		love.graphics.setColor(0.9, 1, 0.9, 0.5*info_alpha)
		if state.threaded then
			love.graphics.print("logic threads: "..threads_count, xl+20, 700-30)
		else
			love.graphics.print("logic threads: 0", xl+20, 700-30)
		end
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

function add_chibis(chibis_count_inc)
	local widths, heights, quads, scale = assets.widths, assets.heights, assets.quads, state.scale
	local chibis_count_new = state.chibis_count+chibis_count_inc
	local n_max = math.ceil(chibis_count_new/threads_count)*10
	local n_left = chibis_count_inc*10
	if state.threaded then
		clear_channels_rsp()
		if state.batch then
			get_chibis_from_threads()
		end
	end
	for i = 1, threads_count do
		if n_left > 0 then
			-- distribute existing chibis
			local buffer, buffer_remaining = chibis[i], buffer_next_remaining(chibis, i+1)
			while buffer_remaining do
				local n = buffer.n
				buffer_move(buffer, buffer_remaining, n_max+buffer.offset)
				if buffer.n < n_max+buffer.offset then
					buffer_remaining = buffer_next_remaining(chibis, i+2)
				else
					break
				end
			end
			-- add new chibis
			while n_left > 0 and buffer.n < n_max+buffer.offset do
				local j = buffer.n+1
				local index = math.random(1, 5)
				local width = widths[index]
				local height = heights[index]
				local movx = math.random()-0.50
				local movy = math.random()-0.50
				local rot_speed = math.random()*180.0-90.0
				local rotx, roty = width/2, height/2
				local x = math.random(width*scale/2+padding, client_w-width*scale/2-padding)
				local y = math.random(height*scale/2+padding, client_h-height*scale/2-padding)
				if movx >= 0 then movx = movx + 0.15 else movx = movx - 0.15 end
				if movy >= 0 then movy = movy + 0.15 else movy = movy - 0.15 end
				buffer[j+0] = index
				buffer[j+1] = x
				buffer[j+2] = y
				buffer[j+3] = movx
				buffer[j+4] = movy
				buffer[j+5] = 0 -- degree
				buffer[j+6] = 0 -- radian
				buffer[j+7] = rot_speed
				buffer[j+8] = rotx
				buffer[j+9] = roty
				spriteBatch:addLayer(index, quads[index], x, y, 0, scale, scale, rotx, roty)
				n_left = n_left-10
				buffer.n = buffer.n + 10
			end
			-- send chibis to threads
			if state.threaded then
				channels_cmd[i]:push({cmd = "chibis", chibis = buffer_trim(buffer)})
			end
		end
	end
	if state.threaded then
		if state.batch then
			channels_cmd[1]:push({cmd = "batch", spriteBatch = spriteBatch})
		end
		send_update(0)
	end
	state.chibis_count = chibis_count_new
end

function get_desc(desc, enabled, nl)
	local result = desc
	if nl then
		if enabled then
			result = result.." (ON/off)\n"
		else
			result = result.." (on/OFF)\n"
		end
	else
		if enabled then
			result = result.." (ON/off)"
		else
			result = result.." (on/OFF)"
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

function quit_app()
	for i = 1, threads_count do
		channels_cmd[i]:push({cmd = "quit"})
	end
	for i = 1, threads_count do
		threads[i]:wait()
	end
	love.event.quit(0)
end

function toggle_threaded()
	state.threaded = not state.threaded
	if state.threaded then
		for i = 1, threads_count do
			channels_cmd[i]:push({cmd = "chibis", chibis = buffer_trim(chibis[i])})
		end
		if state.batch then
			channels_cmd[1]:push({cmd = "batch", spriteBatch = spriteBatch})
		end
		send_update(0)
	else
		-- clear
		clear_channels_rsp()
		if state.batch then
			get_chibis_from_threads()
		end
	end
end

function toggle_batch()
	if state.threaded then
		clear_channels_rsp()
	end
	state.batch = not state.batch
	state.batch_reset = true
	if state.threaded then
		if state.batch then
			channels_cmd[1]:push({cmd = "batch", spriteBatch = spriteBatch})
		end
		send_update(0)
	end
end

function clear_channels_rsp()
	if state.batch then
		channels_rsp[threads_count]:demand()
	else
		for i = 1, threads_count do
			local data = channels_rsp[i]:demand()
			chibis[i] = data.chibis
		end
	end
end

function send_update(dt)
	for i = threads_count, 1, -1 do
		channels_cmd[i]:push({
			cmd = "update",
			scale = state.scale,
			rotating = state.rotating,
			moving = state.moving,
			batch = state.batch,
			speed = state.speed,
			chibis_count = state.chibis_count,
			padding = padding,
			client_w = client_w,
			client_h = client_h,
			dt = dt,
		})
	end
end

function get_chibis_from_threads()
	for i = 1, threads_count do
		channels_cmd[i]:push({cmd = "get"})
	end
	for i = 1, threads_count do
		local data = channels_rsp[i]:demand()
		chibis[i] = data.chibis
	end
end

function update_profiling()
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
end
