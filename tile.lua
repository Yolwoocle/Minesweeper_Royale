require 'util'
local Class = require 'class'
local img = require 'images'

local Tile = Class:inherit()
function Tile:init(ix, iy, val)
	self.ix = ix
	self.iy = iy
	self.val = val
	self.is_bomb = false
	self.is_hidden = true
	self.is_flagged = false
	self.show_number = true
end

function Tile:draw(board, x, y, tile_size, is_select)
	self.show_number = false

	local col = {0,0,0}
	-- Hidden when color
	if self.is_hidden then 
		col = rgb(100, 200, 77)
	end

	-- Lighter color every 2 tiles
	if ((self.ix + self.iy)%2 == 0) then 
		col = lighten_color(col, .2) 
	end 
	
	-- Shown number if number is 1,2,3...
	if self.val > 0 and not self.is_hidden then
		self.show_number = true
	end

	-- Bomb colors
	local is_revealed_bomb = self.is_bomb and not self.is_hidden
	if is_revealed_bomb then 
		col = self.bomb_color
		self.show_number = false
	end


	if is_select then col = lighten_color(col, .4)  end

	love.graphics.setColor(col)
	love.graphics.rectangle("fill", x, y, tile_size, tile_size)
	love.graphics.setColor(1,1,1)

	-- Show number if exposed
	if self.show_number then 
		love.graphics.setColor(board:get_color_of_number(self.val))
		draw_centered_text(self.val, x, y, tile_size, tile_size)
		love.graphics.setColor(1,1,1)
	end
	-- Show flags
	if self.is_flagged then
		love.graphics.draw(img.flag, x, y)
	end
end

function Tile:set_val(val) 
	self.val = val
end

function Tile:set_hidden(val)
	self.is_hidden = val
end
function Tile:is_hidden(val)
	return self.is_hidden
end

function Tile:set_bomb(val)
	self.is_bomb = val
end
function Tile:is_bomb()
	return self.is_bomb
end
function Tile:set_bomb_color(col)
	self.bomb_color = col
end

function Tile:toggle_flag()
	if self.is_flagged then
		self:set_flag(false)
	else
		self:set_flag(true)
	end
end
function Tile:set_flag(v)
	if self.is_hidden then
		self.is_flagged = v
	end
end
function Tile:get_flag()
	return self.is_flagged
end

return Tile