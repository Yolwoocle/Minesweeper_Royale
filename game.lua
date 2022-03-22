local Class = require "class"
local Board = require "board"

local Game = Class:inherit()

function Game:init()
	self.actors = {}
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
end

function Game:mousepressed(x, y, button)
	for i,actor in pairs(self.actors)do
		if actor.mousepressed then  actor:mousepressed(x, y, button)  end
	end
end

return Game