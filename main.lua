local Class = require "class"
local Game = require "game"
local Board = require "board"

local game = Game:new()
function love.load()
		
end

function love.update()
	game:update()
end

function love.draw()
	game:draw()
end


function love.keypressed(key)
	if key == "f5" then
		love.event.quit("restart")
	elseif key == "f4" then
		love.event.quit()
	end
end
