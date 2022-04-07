function load_image(name)
	local im = love.graphics.newImage("images/"..name)
	im:setFilter("nearest", "nearest")
	return im 
end
function load_image_table(name, n, w, h)
	if not n then  error("number of images `n` not defined")  end
	local t = {}
	for i=1,n do 
		t[i] = load_image(name..tostr(i))
	end
	t.w = w
	t.h = h
	return t
end

local img = {}
img.flag = load_image("flag.png")
img.clock = load_image("clock.png")
img.circle = load_image("circle.png")
img.square = load_image("square.png")
img.shovel = load_image("shovel.png")
img.shovel_big = load_image("shovel_48.png")
img.chat = load_image("chat.png")

img.skull = load_image("skull.png")
img.crown = load_image("crown.png")

return img