--          Copyright 2025, Vitali Baumtrok.
-- Distributed under the Boost Software License, Version 1.0.
--     (See accompanying file LICENSE or copy at
--        http://www.boost.org/LICENSE_1_0.txt)

function buffer_append(chibis, buffer)
	local count_rest, chunk, offset, limit
	if chibis.n == 0 then
		count_rest = 0
	else
		count_rest = 10000*10-chibis[chibis.n].n
	end
	if count_rest == 0 or count_rest >= buffer.n then
		if count_rest == 0 then
			chibis.n = chibis.n+1
			if #chibis < chibis.n then
				chunk, offset, limit = {}, 0, 10000*10
				chibis[chibis.n] = chunk
			else
				chunk, offset, limit = chibis[chibis.n], 0, buffer.n
			end
			chunk.n = buffer.n
		else
			chunk = chibis[chibis.n]
			offset, limit, chunk.n = chunk.n, buffer.n, chunk.n+buffer.n
		end
	else
		chunk = chibis[chibis.n]
		offset, limit, chunk.n = chunk.n, count_rest, 10000*10
	end
	for i = 1, limit, 10 do
		chunk[offset+i+0] = buffer[i+0]
		chunk[offset+i+1] = buffer[i+1]
		chunk[offset+i+2] = buffer[i+2]
		chunk[offset+i+3] = buffer[i+3]
		chunk[offset+i+4] = buffer[i+4]
		chunk[offset+i+5] = buffer[i+5]
		chunk[offset+i+6] = buffer[i+6]
		chunk[offset+i+7] = buffer[i+7]
		chunk[offset+i+8] = buffer[i+8]
		chunk[offset+i+9] = buffer[i+9]
	end
	if limit < buffer.n then
		chibis.n = chibis.n+1
		if #chibis < chibis.n then
			chunk, offset, limit = {}, limit, buffer.n-limit
			chibis[chibis.n] = chunk
		else
			chunk, offset, limit = chibis[chibis.n], limit, buffer.n-limit
		end
		chunk.n = limit
		for i = 1, limit, 10 do
			chunk[i+0] = buffer[offset+i+0]
			chunk[i+1] = buffer[offset+i+1]
			chunk[i+2] = buffer[offset+i+2]
			chunk[i+3] = buffer[offset+i+3]
			chunk[i+4] = buffer[offset+i+4]
			chunk[i+5] = buffer[offset+i+5]
			chunk[i+6] = buffer[offset+i+6]
			chunk[i+7] = buffer[offset+i+7]
			chunk[i+8] = buffer[offset+i+8]
			chunk[i+9] = buffer[offset+i+9]
		end
	end
end

function buffer_trim_chibis(chibis)
	local result = {}
	for i = 1, chibis.n do
		result[i] = buffer.chibis[i]
	end
	return result
end