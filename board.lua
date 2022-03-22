require "util"
local Class = require "class"
local Tile = require "tile"
local img = require "images"

local Board = Class:inherit()
function Board:init()
	-- Parameters
	self.w = 19
	self.h = 14
	self.tile_size = 32
	self.number_of_bombs = 30

	self.x = (WINDOW_WIDTH - self.w*self.tile_size) / 2
	self.y = (WINDOW_HEIGHT- self.h*self.tile_size) / 2

	self.is_generated = false
	self.game_over = false
	self.board = {}
	for iy=0, self.h-1 do
		self.board[iy] = {}
		for ix=0, self.w-1 do
			self.board[iy][ix] = Tile:new(ix,iy,0)
		end
	end

	self.numbers_palette = {
		[0] = rgb(0,0,0),
		[1] = rgb(45,45,210),
		[2] = rgb(44,200,44),
		[3] = rgb(255,0,33),
		[4] = rgb(200,255,50),
		[5] = rgb(200,0,255),
		[6] = rgb(0,188,211),
		[7] = rgb(127,127,127),
		[8] = rgb(255,66,234),	
	}
	self.bomb_colors = {
		rgb(223,0,1),
		rgb(246,0,177),
		rgb(245,136,0),
		rgb(239,212,0),
		rgb(0,151,71),
		rgb(97,80,241),
		rgb(199,0,244),
		rgb(58,233,246),
	}
end

function Board:update()
	local tx, ty, isclicked, is_valid = self:get_selected_tile()
	if isclicked and is_valid then 

	end
end

function Board:mousepressed(x, y, button)
	local tx, ty, isclicked, is_valid = self:get_selected_tile()
	if button == 1 then  self:on_button1(tx, ty, is_valid)  end
	if button == 2 then  self:on_button2(tx, ty, is_valid)  end
end

function Board:on_button1(tx, ty, is_valid)
	if is_valid  and not self:get_tile(tx,ty):get_flag() then
		
		if self.is_generated then
			self:reveal_tile(tx, ty)
		else -- If the board is not generated yet
			self:generate_board(tx, ty)
		end
	end
end

function Board:on_button2(tx, ty, is_valid)
	if is_valid then
		self:toggle_flag(tx, ty)
	end
end

function Board:draw()
	local hov_x, hov_y = self:get_selected_tile()

	for iy=0,self.h-1 do
		for ix=0,self.w-1 do
			local tile = self.board[iy][ix]
			
			local x = self.x + ix * self.tile_size 
			local y = self.y + iy * self.tile_size

			tile:draw(self, x, y, self.tile_size, ix == hov_x and iy == hov_y)
		end
	end
end

function Board:get_tile(x, y)
	if self:is_valid_coordinate(x, y)then
		return self.board[y][x]		
	end
end

function Board:set_tile_val(x, y, v)
	if self:is_valid_coordinate(x, y) then
		self.board[y][x]:set_val(v)		
	end
end

function Board:get_selected_tile()
	local isclicked = love.mouse.isDown(1)
	
	local mx, my = love.mouse.getPosition()
	local tx = math.floor((mx-self.x) / self.tile_size)
	local ty = math.floor((my-self.y) / self.tile_size)
	if self:is_valid_coordinate(tx, ty) then
		return tx, ty, isclicked, true
	else
		return nil, nil, isclicked, false
	end
end

function Board:reveal_tile(x, y)
	local tile = self.board[y][x]
	tile.is_hidden = false

	if tile.val == 0 then 
		-- Recursively clear tiles around if it's empty
		self:recursive_reveal_board(x,y)
	end

	-- Game overs if it's a bomb
	if tile.is_bomb then
		self.game_over = true
	end
end

function Board:toggle_flag(x, y)
	self.board[y][x]:toggle_flag()
end
function Board:set_flag(x, y, v)
	self.board[y][x]:set_flag(v)
end
function Board:get_flag(x, y)
	return self.board[y][x]:get_flag()
end

function Board:generate_board(start_x, start_y)
	self.is_generated = true

	-- Generate a list of random bombs
	local i = self.number_of_bombs
	local iters = i*3
	while i > 0 and iters > 0 do
		-- Attempt a random pair of coordinates
		local x = love.math.random(0,self.w-1)
		local y = love.math.random(0,self.h-1)

		-- If valid, update tiles around it
		if not self.board[y][x].is_bomb then
			-- Place bomb
			local is_start_x = is_between(x, start_x-1, start_x+1) 
			local is_start_y = is_between(y, start_y-1, start_y+1)
			local not_at_start_zone = not (is_start_x and is_start_y)
			if not_at_start_zone then

				self.board[y][x]:set_bomb(true)
				self.board[y][x]:set_bomb_color(self:get_random_bomb_color())
				self:update_adjacent_tiles(x, y)
				i = i - 1

			end
			
		end
		iters = iters - 1
	end

	self:recursive_reveal_board(start_x, start_y)
end

function Board:update_adjacent_tiles(x, y)
	for oy=-1,1 do
		for ox=-1,1 do
			if self:is_valid_coordinate(x+ox, y+oy) then
				self.board[y+oy][x+ox].val = self.board[y+oy][x+ox].val + 1
			end
		end
	end
end

function Board:is_valid_coordinate(x, y)
	return is_between(y, 0, self.h-1) and is_between(x, 0, self.w-1)
end

function Board:recursive_reveal_board(x, y)
	-- Reveal tile
	self.board[y][x].is_hidden = false
	
	-- Reveal tiles around
	for oy = -1, 1 do
		for ox = -1, 1 do
			-- If the tile is valid...
			if self:is_valid_coordinate(x+ox, y+oy) then

				local tile = self.board[y+oy][x+ox]
				if tile.is_hidden and tile.val == 0 then
					-- Recursively reveal tiles around
					self.board[y+oy][x+ox].is_hidden = false
					self:recursive_reveal_board(x+ox, y+oy)
				end
				self.board[y+oy][x+ox].is_hidden = false
			
			end
		end
	end
end

function Board:get_color_of_number(num)
	local lim = #self.numbers_palette + 1
	local num = num % lim
	return self.numbers_palette[num]
end

function Board:get_random_bomb_color()
	local r = love.math.random(1, #self.bomb_colors)
	return self.bomb_colors[r]
end

return Board