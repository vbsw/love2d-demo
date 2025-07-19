--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

require("love.thread")
require("love.graphics")
require("buffer")

local channel_cmd, channel_rsp = ...

local assets = {
	widths = {512, 399, 400, 347, 418},
	heights = {443, 512, 512, 512, 512},
	quads = {}
}
for i, width in ipairs(assets.widths) do
	local hight = assets.heights[i]
	assets.quads[i] = love.graphics.newQuad(0, 0, width, hight, 512, 512)
end
local chibis = {n = 0}
local data = channel_cmd:demand()
local running = data.cmd ~= "quit"
local spriteBatch

while running do

	if data.cmd == "update" then
		local scale, padding, client_w, client_h, dt = data.scale, data.padding, data.client_w, data.client_h, data.dt
		if data.rotating then
			for i = 1, chibis.n do
				local chunk = chibis[i]
				for j = 1, chunk.n, 10 do
					local r_degrees = chunk[j+5] + chunk[j+7]*dt -- r=r*rot_speed*dt
					if r_degrees > 360 then
						r_degrees = r_degrees - 360
					elseif r_degrees < -360 then
						r_degrees = r_degrees + 360
					end
					chunk[j+5] = r_degrees
					chunk[j+6] = math.rad(r_degrees)
				end
			end
		end
		if data.moving then
			local widths, heights = assets.widths, assets.heights
			local speed = data.speed
			for i = 1, chibis.n do
				local chunk = chibis[i]
				for j = 1, chunk.n, 10 do
					local index, x, y, movx, movy = chunk[j], chunk[j+1], chunk[j+2], chunk[j+3], chunk[j+4]
					local width, height = widths[index], heights[index]
					if (x - width*scale/2 < padding and movx < 0) or (x > client_w - (width*scale/2+padding) and movx > 0) then
						movx = -1 * movx
					end
					if (y - height*scale/2 < padding and movy < 0) or (y > client_h - (height*scale/2+padding) and movy > 0) then
						movy = -1 * movy
					end
					chunk[j+1], chunk[j+3] = x + movx*dt*speed, movx
					chunk[j+2], chunk[j+4] = y + movy*dt*speed, movy
				end
			end
		end
		if data.updateBatch then
			local quads, chibiIdx = assets.quads, 0
			for i = 1, chibis.n do
				local chunk = chibis[i]
				for j = 1, chunk.n, 10 do
					local index, x, y, radian, rx, ry = chunk[j], chunk[j+1], chunk[j+2], chunk[j+6], chunk[j+8], chunk[j+9]
					chibiIdx = chibiIdx + 1
					spriteBatch:setLayer(chibiIdx, index, quads[index], x, y, radian, scale, scale, rx, ry)
				end
			end
		end
		channel_rsp:push({chibis = chibis, spriteBatch = spriteBatch})
	elseif data.cmd == "new" then
		for i, chunk in ipairs(data.chibis) do
			chibis[i] = chunk
		end
		chibis.n = data.chibis.n
		spriteBatch = data.spriteBatch
	elseif data.cmd == "append" then
		local quads, buffer, scale = assets.quads, data.buffer, data.scale
		buffer_append(chibis, buffer)
		for i = 1, buffer.n, 10 do
			local index, x, y, radian, rx, ry = buffer[i], buffer[i+1], buffer[i+2], buffer[i+6], buffer[i+8], buffer[i+9]
			spriteBatch:addLayer(index, quads[index], x, y, radian, scale, scale, rotx, roty)
		end
	elseif data.cmd == "clear" then
		chibis.n = 0
	end

	data = channel_cmd:demand()
	running = data.cmd ~= "quit"

end
