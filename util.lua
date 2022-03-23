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

function draw_centered_text(text, rect_x, rect_y, rect_w, rect_h)
	local font   = love.graphics.getFont()
	local text_w = font:getWidth(text)
	local text_h = font:getHeight()
	love.graphics.print(text, rect_x+rect_w/2, rect_y+rect_h/2, 0, 1, 1, text_w/2, text_h/2)
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