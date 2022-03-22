local Class = require "class"
local Board = require "board"

local Game = Class:inherit()

function Game:init()
	self.actors = {}
	self.debugmode = true
	table.insert(self.actors, Board:new())
end

function Game:update()
	for i,actor in pairs(self.actors)do
		actor:update()
	end
end

function Game:draw()
	local a = .1
	love.graphics.clear(a,a,a)
	for i,actor in pairs(self.actors)do
		actor:draw()
	end

	love.graphics.setColor(1,1,1)
	if self.debugmode then
		love.graphics.print("FPS "..love.timer.getFPS(), 2,2)
	end
end

function Game:mousepressed(x, y, button)
	for i,actor in pairs(self.actors)do
		if actor.mousepressed then  actor:mousepressed(x, y, button)  end
	end
end

function Game:keypressed(key)
	if key == "f3" then
		self.debugmode = not self.debugmode
	end
end

return Game