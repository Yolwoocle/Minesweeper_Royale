local Class = require "class"
local Game = require "game"
local Board = require "board"
local NetworkManager = require "network"

-- Global parameters
WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

local game = Game:new()

function love.load()
	love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)

	-- Load fonts
	local font_regular = love.graphics.newFont("fonts/Poppins-Regular.ttf", 24)
	love.graphics.setFont(font_regular)
end

function love.update(dt)
	game:update(dt)
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

	if game.keypressed then  game:keypressed(key)  end
end

function love.mousepressed(x, y, button, istouch, presses)
	game:mousepressed(x, y, button)
end