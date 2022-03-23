local Class = require "class"
local Board = require "board"
local NetworkManager = require "network"

local Game = Class:inherit()

--Guigui load font changer si possible pin
local font_regular = love.graphics.newFont("fonts/Poppins-Regular.ttf", 24)

function Game:init()
	love.graphics.setFont(font_regular)
	
	self.actors = {}
	self.actors.board = Board:new()

	self.network_manager = nil
	self.debugmode = true
end

function Game:update(dt)
	for i,actor in pairs(self.actors)do
		actor:update(dt)
	end
	
	-- TEMPORAIRE:
	if self.network_manager then 
		self.network_manager:update(dt)
	else
		if love.keyboard.isDown("c") then
			self.network_manager = NetworkManager:new("client")
			self.actors.board.network = self.network_manager.network
		elseif love.keyboard.isDown("s") then
			self.network_manager = NetworkManager:new("server", self)
			self.actors.board.network = self.network_manager.network
		end
	end

end

function Game:draw()
	local a = .1
	if self.network_manager then
		if self.network_manager.network_type == "server" then
			a=.9 
		end
	end
	love.graphics.clear(a,a,a)

	for i,actor in pairs(self.actors)do
		actor:draw()
	end

	if self.actors.board.game_over then
		--RECTANGLE rgb(120,120,233),0.4)
		love.graphics.setColor(0.3,0.3,0.5,0.7)
		local rect_width = 0.30*WINDOW_WIDTH
		local rect_height = 0.30*WINDOW_HEIGHT
		love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

		--TEXT
		love.graphics.setColor(1,1,1)
		local lose_text = "ta pairdu"
		local text_width = font_regular:getWidth(lose_text)
		local text_height = font_regular:getHeight(lose_text)
		love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
		
		lose_text = "tu veux rejouer ?"
		text_width = font_regular:getWidth(lose_text)
		text_height = font_regular:getHeight(lose_text)
		love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2)
	end

	-- DEBUGGING
	love.graphics.setColor(1,1,1)
	if self.debugmode then
		love.graphics.print("FPS "..love.timer.getFPS(), 2,2)
	end
	if self.network_manager then
		love.graphics.print(concat('Network type=',self.network_manager.network_type), 30,30)
	else
		love.graphics.print("Select network type (press c/s)", 30,30)
	end
end

function Game:mousepressed(x, y, button)
	if button == 1 then
		for i,actor in pairs(self.actors)do
			if actor.mousepressed then  actor:mousepressed(x, y, button)  end
		end
	elseif button == 2 then  
		self:on_button2()
	end
end

function Game:on_button1(tx, ty, is_valid)
	for i,actor in pairs(self.actors)do
		if actor.on_button1 then  actor:on_button1(tx, ty, is_valid)  end
	end
end

function Game:keypressed(key)
	if key == "f3" then
		self.debugmode = not self.debugmode
	end
end

return Game