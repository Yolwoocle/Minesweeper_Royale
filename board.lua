require "util"
local Class = require "class"
local Tile = require "tile"

local Board = Class:inherit()
function Board:init()
	-- Parameters
	self.x = 0
	self.y = 0
	self.w = 19
	self.h = 14
	self.tile_size = 32
	self.number_of_mines = 30

	self.is_generated = false
	self.game_over = false
	self.board = {}

	--creation d'un tableau
	for i=0,self.h-1 do
		self.board[i] = {}
		for j=0,self.w-1 do
			self.board[i][j] = Tile:new(0)
		end
	end
end

function Board:update()
	local tx, ty, isclicked = self:get_selected_tile()
	if isclicked then 
		if self.is_generated then
			
		else -- If the board is not generated
			self:generate_board(tx, ty)
		end
	end
-- vérifie si la case existe puis regarde en cas de clique si il y a une bombe --
	if self:is_valid_coordinate(tx,ty) then
		print(self.board[ty][tx].val)
		if isclicked and self.board[ty][tx] == math.huge then
			self.game_over = true
			print('hi')
		end
	end

end

function Board:draw()
	local hov_x, hov_y = self:get_selected_tile()

	for iy=0,self.h-1 do
		for ix=0,self.w-1 do
			local tile = self.board[iy][ix]
			local tile_val = tile.val
			
			-- Color
			local col = {0,0,0}
			if tile.is_hidden then 
				col = {0, 1, 0}
			else
				if tile.is_mine then                col = {1, 0, 0}  end
			end
			-- Lighter color
			if (ix+iy)%2==0 then col = lighten_color(col, .2) end 
			if ix == hov_x and iy == hov_y then col = lighten_color(col, .4)  end

			local x = self.x + ix * self.tile_size 
			local y = self.y + iy * self.tile_size

			love.graphics.setColor(col)
			love.graphics.rectangle("fill", x, y, self.tile_size, self.tile_size)
			love.graphics.setColor(1,1,1)
			if tile_val > 0 and not tile.is_hidden then 
				love.graphics.print(tostring(tile_val), x, y)
			end
		end
	end
end

function Board:get_tile(x, y)
	if self:is_valid_coordinate(x, y)then
		return self.board[y][x]		
	end
end

function Board:generate_board(start_x, start_y)
	self.is_generated = true

	-- Generate a list of random mines
	local i = self.number_of_mines
	local iters = i*3
	while i > 0 and iters > 0 do
		-- Attempt a random pair of coordinates
		local x = love.math.random(0,self.w-1)
		local y = love.math.random(0,self.h-1)

		-- If valid, update tiles around it
		if self.board[y][x] ~= math.huge then
			-- Place mine
			local is_start_x = is_between(x, start_x-1, start_x+1) 
			local is_start_y = is_between(y, start_y-1, start_y+1)
			local not_at_start_zone = not (is_start_x and is_start_y)
			if not_at_start_zone then
				self.board[y][x].is_mine = true
			end
			
			-- Update adjacent tiles
			for oy=-1,1 do
				for ox=-1,1 do
					if self:is_valid_coordinate(x+ox, y+oy) then
						self.board[y+oy][x+ox].val = self.board[y+oy][x+ox].val + 1
					end
				end
			end
			i = i - 1
		end
		iters = iters - 1
	end

	self:recursive_reveal_board(start_x, start_y)
end

function Board:get_selected_tile()
	local isclicked = love.mouse.isDown(1)
	
	local mx, my = love.mouse.getPosition()
	local tx = math.floor((mx-self.x) / self.tile_size)
	local ty = math.floor((my-self.y) / self.tile_size)
	if self:is_valid_coordinate(tx, ty) then
		return tx, ty, isclicked
	else
		return nil, nil, isclicked
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

return Board