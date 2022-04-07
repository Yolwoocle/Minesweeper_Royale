local Class = require "class"
local Board = require "board"
local Client = require "client"
local Server = require "server"
local NetworkManager = require "network"
local ParticleSystem = require "particlesystem"
local AudioManager = require "audio"
local Chat = require "chat"
local font = require "font"

local Game = Class:inherit()

-- GLOBAL SINGLETONS
particles = ParticleSystem:new()
audio = AudioManager:new()
chat = Chat:new()

function notification(...)
	chat:new_msg("%y"..concat(...))
end

function Game:init(is_server)
	-- GLOBAL SINGLETONS
	particles = ParticleSystem:new()
	audio = AudioManager:new()
	chat = Chat:new()

	love.graphics.setFont(font.regular)
	self.user_type = nil --"client" or "server"
	if is_server then
		self.background_color = {.3, .3, .3}
		self.interface = Server:new() --Either Client or Server 
	else
		self.background_color = {.1, .1, .1}
		self.interface = Client:new() --Either Client or Server 
	end

	-- Update chat parent
	chat.parent = self.interface

	-- Chat
	self.display_chat = false

	self.debugmode = false
end

function Game:update(dt)
	if self.interface and self.interface.update then
		-- interface represents either a Client or Server
		self.interface:update(dt)
	end
	chat:update(dt)
	particles:update(dt)

end

function Game:draw()
	love.graphics.clear(self.background_color)
	if self.interface and self.interface.draw then
		-- interface represents either a Client or Server
		self.interface:draw()
	end
end

function Game:mousepressed(x, y, button)
	if self.interface.mousepressed then  self.interface:mousepressed(x,y,button)  end
end

function Game:on_button1(tx, ty, is_valid)
	if self.interface.on_button1 then  self.interface:on_button1(tx, ty, is_valid)  end
end
function Game:on_button2()
	if self.interface.on_button2 then  self.interface:on_button2(tx, ty, is_valid)  end
end

function Game:keypressed(key)
	if self.interface.keypressed then  self.interface:keypressed(key)  end
	chat:keypressed(key)
	
	if key == "f3" then
		self.debugmode = not self.debugmode
	end
end

function Game:quit()
	if self.interface.quit then  self.interface:quit()  end
end

function Game:textinput(text)
	chat:textinput(text)
end

return Game