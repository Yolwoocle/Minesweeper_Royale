require "util"
local Class = require "class"

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

	self.board = {}
	for i=0,self.h-1 do
		self.board[i] = {}
		for j=0,self.w-1 do
			self.board[i][j] = 0
		end
	end
end

function Board:update()
	local tx, ty, isclicked = self:get_selected_tile()
	if isclicked and not self.is_generated then
		self:generate_board(tx, ty)
	end
end

function Board:draw()
	local hov_x, hov_y = self:get_selected_tile()

	for iy=0,self.h-1 do
		for ix=0,self.w-1 do
			local tile_val = self.board[iy][ix]
			
			local col = (ix+iy)%2==0 and {.2,.2,.2} or {0,0,0}
			if tile_val == math.huge then  col = {1,0,0}  end
			if ix == hov_x and iy == hov_y then  col = {.5,.5,.5}  end

			local x = self.x + ix * self.tile_size 
			local y = self.y + iy * self.tile_size

			love.graphics.setColor(col)
			love.graphics.rectangle("fill", x, y, self.tile_size, self.tile_size)
			love.graphics.setColor(1,1,1)
			if tile_val > 0 or true then 
				love.graphics.print(tostring(tile_val), x, y)
			end
		end
	end
end

function Board:get_selected_tile()
	local isclicked = love.mouse.isDown(1)
	
	local mx, my = love.mouse.getPosition()
	local tx = math.floor((mx-self.x) / self.tile_size)
	local ty = math.floor((my-self.y) / self.tile_size)

	return tx, ty, isclicked
end

function Board:generate_board(start_x, start_y)
	self.is_generated = true

	-- Generate a list of random mines
	local mines = {}
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
				self.board[y][x] = math.huge
			end
			
			-- Update adjacent tiles
			for oy=-1,1 do
				for ox=-1,1 do
					if self:is_valid_coordinate(x+ox, y+oy) then
						self.board[y+oy][x+ox] = self.board[y+oy][x+ox] + 1
					end
				end
			end
			i = i - 1
		end
		iters = iters - 1
	end
end

function Board:is_valid_coordinate(x, y)
	return is_between(y, 0, self.h-1) and is_between(x, 0, self.w-1)
end

return Board