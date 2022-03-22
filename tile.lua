require 'util'
local Class = require 'class'
local img = require 'images'

local Tile = Class:inherit()
function Tile:init(ix, iy, val)
	self.ix = ix
	self.iy = iy
	self.val = val
	self.is_mine = false
	self.is_hidden = true
	self.is_flagged = false
end

function Tile:draw(x, y, tile_size, is_select)
	-- Color
	local col = {0,0,0}
	if self.is_hidden then 
		col = rgb(100, 200, 77)
	else
		if self.is_mine then col = rgb(255,0,0) end
	end
	-- Lighter color
	if (self.ix + self.iy)%2 == 0 then col = lighten_color(col, .2) end 
	if is_select then col = lighten_color(col, .4)  end

	love.graphics.setColor(col)
	love.graphics.rectangle("fill", x, y, tile_size, tile_size)
	love.graphics.setColor(1,1,1)
	if self.val > 0 and not self.is_hidden then 
		love.graphics.print(tostring(self.val), x, y)
	end
	if self.is_flagged then
		love.graphics.draw(img.flag, x, y)
	end
end

return Tile