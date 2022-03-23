local socket = require "socket"
local Class = require "class"

local Client = Class:inherit()
function Client:init()
	print('CLIENT SAYZ HELLO CHEZBURGER')

	self.address = "localhost"
	self.port = 12345

	self.updaterate = 0.1 -- how long to wait, in seconds, before requesting an update

	self.num = 0 

	self.udp = socket.udp()
	self.udp:settimeout(0)
	self.udp:setpeername(self.address, self.port)
	
	local dg = "I'm ready! :D"
	self.udp:send(dg) 
	
	self.t = 0 
end
function Client:update(dt)
	self.t = self.t + dt 

	if self.t > self.updaterate then
		local msg = "waiting"
		if love.keyboard.isDown('up') then 	
			msg = "did a thing"--..tostring(love.math.random(1,100)) 
		end

		-- Send the packet
		local dg = msg
		self.udp:send(dg)	

		-- Request world update
		local dg = "PLZ UPDATE"
		self.udp:send(dg)
		
		-- Set t for the next round
		self.t = self.t - self.updaterate 
	end

	-- Fetch all messages (there could be multiple!)
	repeat
		local data, msg = self.udp:receive()
		if msg ~= "timeout" then 
			print("data, msg:", data, msg)
		end

		if data then 
			local cmd, num = data:match("^(%S+) (%d+)")

			if cmd == 'number' then
				print("Correctly recieved server msg:", num)
				self.num = num
			else
				print("Unrecognised server command:", cmd)
			end
		
		-- If data was nil, msg will contain a description of the problem.
		elseif msg ~= 'timeout' then 
			error("Network error: "..tostring(msg))
		end
	until not data 
end

return Client