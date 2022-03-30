local img = require "images"

function is_between(v, a, b)
	return a <= v and v <= b
end

function lighten_color(col, v)
	local ncol = {}
	for i,ch in pairs(col) do
		table.insert(ncol, ch+v)
	end
	return ncol
end

function rgb(r,g,b)
	return {r/255, g/255, b/255}
end

function draw_centered_text(text, rect_x, rect_y, rect_w, rect_h, rot, sx, sy)
	rot = rot or 0
	sx = sx or 1
	sy = sy or sx
	local font   = love.graphics.getFont()
	local text_w = font:getWidth(text)
	local text_h = font:getHeight(text)
	love.graphics.print(text, rect_x+rect_w/2, rect_y+rect_h/2, rot, sx, sy, text_w/2, text_h/2)
end

function print_centered(text, x, y, rot, sx, sy)
	rot = rot or 0
	sx = sx or 1
	sy = sy or sx
	local font   = love.graphics.getFont()
	local text_w = font:getWidth(text)
	local text_h = font:getHeight(text)
	love.graphics.print(text, x-text_w/2, y-text_h/2, rot, sx, sy)
end

function concat(...)
	local args = {...}
	local s = ""
	for _,v in pairs(args) do
		s = s..tostring(v)
	end
	return s
end

function bool_to_int(b)
	if b then
		return 1
	end
	return 0
end

function clamp(a, b, c)
	return math.min(math.max(a, b), c)
end

function smooth_circle(type, x, y, r, col)
	love.graphics.setColor(col)
	love.graphics.setPointSize(r)
	love.graphics.setPointStyle("smooth")
	love.graphics.points(x,y)
	love.graphics.setColor(1,1,1)
end

function get_rank_color(rank, defcol)
	if rank == 1 then
		return rgb(255,206,33)
	elseif rank == 2 then
		return rgb(120,163,193)
	elseif rank == 3 then
		return rgb(218,75,29)
	else
		return defcol
	end
end

function split_str(inputstr, sep)
	if sep == nil then
		sep = "%s"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		table.insert(t, str)
	end
	return t
end

function draw_rank_medal(rank, defcol, x, y)
	--- Circle
	local rank_col = get_rank_color(rank, defcol)
	love.graphics.setColor(rank_col)
	love.graphics.draw(img.circle, x, y)
	--- Text
	love.graphics.setColor(1,1,1)
	print_centered(rank, x+16, y+16)
	--- 1"er", 2"e"...
	local e = rank==1 and "er" or "e"
	print_centered(e, x+32, y+12, 0, .75)
end

function tobool(str)
	return str ~= "false" -- Anything other than "false" returns as true
end

function random_neighbor(n)
	return love.math.random()*2*n - n
end

function random_range(a,b)
	return love.math.random()*(b-a) + a
end

function random_sample(t)
	return t[love.math.random(1,#t)]
end