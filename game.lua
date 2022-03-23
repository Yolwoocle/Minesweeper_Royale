local Class = require "class"
local Board = require "board"
local NetworkManager = require "network"

local Game = Class:inherit()

function Game:init()
	self.actors = {}
	self.actors.board = Board:new()

	self.network = nil
	self.debugmode = true
end

function Game:update(dt)
	for i,actor in pairs(self.actors)do
		actor:update(dt)
	end
	if self.network then 
		self.network:update(dt)
	else
		if love.keyboard.isDown("c") then
			self.network = NetworkManager:new("client")
		elseif love.keyboard.isDown("s") then
			self.network = NetworkManager:new("server")
		end
	end
end

function Game:draw()
	local a = .1
	love.graphics.clear(a,a,a)
	for i,actor in pairs(self.actors)do
		actor:draw()
	end

	-- DEBUGGING
	love.graphics.setColor(1,1,1)
	if self.debugmode then
		love.graphics.print("FPS "..love.timer.getFPS(), 2,2)
	end
	if self.network then
		love.graphics.print(concat('type=',self.network.network_type,",num=",self.network.network.num), 30,30)
	else
		love.graphics.print("Select network type (press c/s)", 30,30)
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