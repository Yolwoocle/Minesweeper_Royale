local socket = require "socket"
local Class = require "class"
local Client = require "client"
local Server = require "server"

local NetworkManager = Class:inherit()
function NetworkManager:init(t, game)
	self.network = nil
	self.network_type = t

	if t == "client" then
		self.network = Client:new()
	elseif t == "server" then
		self.network = Server:new(game) 
	end
end
function NetworkManager:update(dt)
	self.network:update(dt)
end

return NetworkManager