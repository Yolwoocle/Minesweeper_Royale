require "util"
local Class = require "class"

local Board = Class:inherit()
function Board:init()
	self.x = 40
	self.y = 70
	self.w = 19
	self.h = 14
	self.tile_size = 32

	self.board = {}
	for i=1,self.h do
		self.board[i] = {}
		for j=1,self.w do
			self.board[i][j] = 0
		end
	end

	self:generate_board()
end

function Board:update()

end

function Board:draw()
	local hov_x, hov_y = self:get_hovered_tile()

	for i=1,self.h do
		for j=1,self.w do
			local x = self.x + (j-1)*self.tile_size 
			local y = self.y + (i-1)*self.tile_size
			local tile_val = self.board[i][j]
			
			local col = (i+j)%2==0 and {.2,.2,.2} or {0,0,0}
			if tile_val == math.huge then  col = {1,0,0}  end
			if x == hov_x and y == hov_y then  col = {.5,.5,.5}  end

			love.graphics.setColor(col)
			love.graphics.rectangle("fill", x, y, self.tile_size, self.tile_size)
			love.graphics.setColor(1,1,1)
			love.graphics.print(tostring(tile_val), x, y)
		end
	end
end

function Board:generate_board()
	local number_of_mines = 30 --40
	-- Generate a list of random mines
	local mines = {}
	local i = 10
	local iters = i+100
	while i > 0 and iters > 0 do
		-- Attempt a random pair of coordinates
		local x = love.math.random(1,self.w)
		local y = love.math.random(1,self.h)
		-- If valid, update tiles around it
		if self.board[y][x] == 0 then
			self.board[y][x] = math.huge
			for oy=-1,1 do
				for ox=-1,1 do
					if is_between(y+oy, 1, self.h) and is_between(x+ox, 1, self.w) then
						self.board[y+oy][x+ox] = self.board[y+oy][x+ox] + 1
					end
				end
			end
			i = i - 1
		end
		iters = iters - 1
	end
end

function Board:get_hovered_tile()
	local mx, my = love.mouse.getPosition()
	local tx = (mx-self.x) / self.tile_size
	local ty = (my-self.y) / self.tile_size
	return math.floor(tx), math.floor(ty)
end

return Board