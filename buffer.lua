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

function buffer_trim(buffer)
	local offset = buffer.offset
	local unused = offset+(#buffer-buffer.n)
	local used = buffer.n-offset
	if unused > used or unused > 4999*10 then
		local buffer_new = {}
		for i = 1, buffer.n, 10 do
			buffer_new[i+0] = buffer[offset+i+0]
			buffer_new[i+1] = buffer[offset+i+1]
			buffer_new[i+2] = buffer[offset+i+2]
			buffer_new[i+3] = buffer[offset+i+3]
			buffer_new[i+4] = buffer[offset+i+4]
			buffer_new[i+5] = buffer[offset+i+5]
			buffer_new[i+6] = buffer[offset+i+6]
			buffer_new[i+7] = buffer[offset+i+7]
			buffer_new[i+8] = buffer[offset+i+8]
			buffer_new[i+9] = buffer[offset+i+9]
		end
		buffer_new.offset, buffer_new.n = 0, buffer.n-buffer.offset
		return buffer_new
	end
	return buffer
end

function buffer_move(buffer_dest, buffer_src, n_max)
	local i, j, n_src = buffer_dest.n+1, buffer_src.offset+1, buffer_src.n
	while i < n_max and j < n_src do
		buffer_dest[i+0] = buffer_src[j+0]
		buffer_dest[i+1] = buffer_src[j+1]
		buffer_dest[i+2] = buffer_src[j+2]
		buffer_dest[i+3] = buffer_src[j+3]
		buffer_dest[i+4] = buffer_src[j+4]
		buffer_dest[i+5] = buffer_src[j+5]
		buffer_dest[i+6] = buffer_src[j+6]
		buffer_dest[i+7] = buffer_src[j+7]
		buffer_dest[i+8] = buffer_src[j+8]
		buffer_dest[i+9] = buffer_src[j+9]
		i, j = i+10, j+10
	end
	buffer_dest.n = i-1
	if j < n_src then
		buffer_src.offset = j-1
	else
		buffer_src.offset, buffer_src.n = 0, 0
	end
end

function buffer_next_remaining(buffers, j)
	for i = j, #buffers do
		local buffer = buffers[i]
		if buffer.offset < buffer.n then
			return buffer
		end
	end
	return nil
end
