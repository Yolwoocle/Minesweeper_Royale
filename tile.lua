require 'util'
require 'constants'
local Class = require 'class'
local img = require 'images'
local sfx = require 'sfx'

local Tile = Class:inherit()
function Tile:init(board, ix, iy, x, y, val)
	self.board = board
	self.x = x
	self.y = y
	self.ix = ix
	self.iy = iy
	self.val = val
	self.is_bomb = false
	self.is_hidden = true
	self.is_flagged = false
	self.show_number = true
	self.scale = scale
	self.is_lighter = ((ix + iy)%2 == 0)
end

function Tile:draw(board, x, y, scale, tile_size, is_select)
	self.show_number = false
	scale = scale or 1

	-- Deafult revealed color
	local col = COL_REVEALED
	-- Hidden when color
	if self.is_hidden then 
		col = COL_HIDDEN
	end

	-- Lighter color every 2 tiles
	if ((self.ix + self.iy)%2 == 0) then 
		col = lighten_color(col, .1) 
	end 
	
	-- Show number if number is 1,2,3...
	if self.val > 0 and not self.is_hidden then
		self.show_number = true
	end

	-- Bomb colors
	local is_revealed_bomb = self.is_bomb and not self.is_hidden
	if is_revealed_bomb then 
		col = self.bomb_color
		self.show_number = false
	end

	-- Draw rectangle
	love.graphics.setColor(col)
	love.graphics.rectangle("fill", x, y, tile_size, tile_size)
	-- Selection indicator
	if is_select then 
		love.graphics.setColor(1,1,1, .4)
		love.graphics.rectangle("fill", x, y, tile_size, tile_size)
	end
	-- Show bomb
	if is_revealed_bomb then
		local ccol = lighten_color(col, -.2)
		local o = tile_size/2
		love.graphics.setColor(ccol)
		love.graphics.circle("fill", x+o, y+o, tile_size*.25)	
	end
	-- Show number if exposed
	if self.show_number then 
		love.graphics.setColor(board:get_color_of_number(self.val))
		draw_centered_text(self.val, x, y, tile_size, tile_size, 0, scale)
		love.graphics.setColor(1,1,1)
	end
	-- Show flags
	if self.is_flagged then
		love.graphics.setColor(1,1,1)
		love.graphics.draw(img.flag, x, y, 0, scale)
	end
	love.graphics.setColor(1,1,1)
end

function Tile:set_val(val) 
	self.val = val
end

function Tile:set_hidden(val)
	local output
	if (not val) and self.is_hidden then  
		output = true
		self:on_revealed()
	end
	self.is_hidden = val
	return output
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
		-- Remove flag
		self:set_flag(false)
		self.board.remaining_flags = self.board.remaining_flags + 1 
		self:particle(img.flag)
		audio:play(sfx.flag_remove)
		return false
	else
		-- Place flag
		self:set_flag(true)
		self.board.remaining_flags = self.board.remaining_flags - 1  
		if self.is_hidden then 
			audio:play_random(sfx.flag_place_list)
		end
		return true
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

function Tile:on_revealed()
	self.board.number_of_broken_tiles = self.board.number_of_broken_tiles + 1
	-- Particles
	--img, x, y, r, s, dx, dy, dr, ds, g, fx, fy, fr, fs	
	self:particle({img.square, COL_HIDDEN}) 
	
	-- SFX
	audio:play_random(sfx.break_list)

	--If it's a bomb, play SFX & particles
	if self.is_bomb then
		audio:play_random(sfx.bomb_explode_list)
		self:confetti({img.square, self.bomb_color}, 0.5, 10)
	end
end

function Tile:particle(img, scale, number)
	scale = scale or 1
	number = number or 1

	local ts2 = self.board.tile_size/2
	local x = self.board.x + (self.ix+.5)*self.board.tile_size
	local y = self.board.y + (self.iy+.5)*self.board.tile_size
	local s = self.board.scale * scale
end

function Tile:confetti(number)
	number = number or 1

	local scale = random_range(0.3,0.7)

	local ts2 = self.board.tile_size/2
	local x = self.board.x + (self.ix+.5)*self.board.tile_size
	local y = self.board.y + (self.iy+.5)*self.board.tile_size
	local s = self.board.scale * scale

	for i=1, number do
		particles:new_thrown_particle(img,x,y,s)
	end
end

return Tile