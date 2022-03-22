local Class = require "class"
local Game = require "game"
local Board = require "board"

local game = Game:new()
function love.load()
	-- Load fonts
	local font_regular = love.graphics.newFont("fonts/Poppins-Regular.ttf", 24)
	love.graphics.setFont(font_regular)
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

function love.mousepressed(x, y, button, istouch, presses)
	game:mousepressed(x, y, button)
end