--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

require("love.thread")
require("love.graphics")
require("buffer")

local threads_count, channel_cmd, channel_rsp, channel_nxt, id = ...

local assets = {
	widths = {512, 399, 400, 347, 418},
	heights = {443, 512, 512, 512, 512},
	quads = {},
}
for i, width in ipairs(assets.widths) do
	local hight = assets.heights[i]
	assets.quads[i] = love.graphics.newQuad(0, 0, width, hight, 512, 512)
end
local batch = false
local chibis = {n = 0}
local data = channel_cmd:demand()
local running = data.cmd ~= "quit"
local spriteBatch
local scale = 1

while running do

	if data.cmd == "update" then
		local chibis_count, padding, client_w, client_h, dt = data.chibis_count, data.padding, data.client_w, data.client_h, data.dt
		local sprites_offset = math.ceil(chibis_count/threads_count)*(id-1)
		local batch_reset, batch = (batch ~= data.batch), data.batch
		local updateBatch = data.batch and (data.rotating or data.moving or batch_reset)
		scale = data.scale
		if data.rotating then
			for i = chibis.offset+1, chibis.n, 10 do
				local r_degrees = chibis[i+5] + chibis[i+7]*dt -- r=r*rot_speed*dt
				if r_degrees > 360 then
					r_degrees = r_degrees - 360
				elseif r_degrees < -360 then
					r_degrees = r_degrees + 360
				end
				chibis[i+5] = r_degrees
				chibis[i+6] = math.rad(r_degrees)
			end
		end
		if data.moving then
			local widths, heights = assets.widths, assets.heights
			local speed = data.speed
			for i = chibis.offset+1, chibis.n, 10 do
				local index, x, y, movx, movy = chibis[i], chibis[i+1], chibis[i+2], chibis[i+3], chibis[i+4]
				local width, height = widths[index], heights[index]
				if (x - width*scale/2 < padding and movx < 0) or (x > client_w - (width*scale/2+padding) and movx > 0) then
					movx = -1 * movx
				end
				if (y - height*scale/2 < padding and movy < 0) or (y > client_h - (height*scale/2+padding) and movy > 0) then
					movy = -1 * movy
				end
				chibis[i+1], chibis[i+3] = x + movx*dt*speed, movx
				chibis[i+2], chibis[i+4] = y + movy*dt*speed, movy
			end
		end
		if updateBatch and id == 1 then
			local quads, spriteIdx = assets.quads, sprites_offset
			for i = chibis.offset+1, chibis.n, 10 do
				local index, x, y, radian, rx, ry = chibis[i], chibis[i+1], chibis[i+2], chibis[i+6], chibis[i+8], chibis[i+9]
				spriteIdx = spriteIdx + 1
				spriteBatch:setLayer(spriteIdx, index, quads[index], x, y, radian, scale, scale, rx, ry)
			end
		end
		if updateBatch then
			if id == 1 then
				channel_nxt:push({cmd = "batch", chibis_count = chibis_count, spriteBatch = spriteBatch})
			end
		else
			channel_rsp:push({chibis = chibis})
		end
	elseif data.cmd == "chibis" then
		chibis = data.chibis
	elseif data.cmd == "batch" then
		if id == 1 then
			spriteBatch = data.spriteBatch
		else
			local spriteBatch = data.spriteBatch
			local sprites_offset = math.ceil(data.chibis_count/threads_count)*(id-1)
			local quads, spriteIdx = assets.quads, sprites_offset
			for i = chibis.offset+1, chibis.n, 10 do
				local index, x, y, radian, rx, ry = chibis[i], chibis[i+1], chibis[i+2], chibis[i+6], chibis[i+8], chibis[i+9]
				spriteIdx = spriteIdx + 1
				spriteBatch:setLayer(spriteIdx, index, quads[index], x, y, radian, scale, scale, rx, ry)
			end
			channel_nxt:push({cmd = "batch", chibis_count = data.chibis_count, spriteBatch = spriteBatch})
		end
	elseif data.cmd == "get" then
		channel_rsp:push({chibis = chibis})
	elseif data.cmd == "clear" then
		chibis.offset, chibis.n = 0, 0
	end

	data = channel_cmd:demand()
	running = data.cmd ~= "quit"

end
