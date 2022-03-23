local socket = require "socket"
local Class = require "class"

local Server = Class:inherit()

function Server:init()
	-- begin
	self.udp = socket.udp()
	self.udp:settimeout(0)

	self.udp:setsockname('*', 12345)

	self.num = 100
	self.running = true
	
	print "Beginning server loop."
end

function Server:update(dt)
	local data, msg_or_ip, port_or_nil
	local entity, cmd, parms

	if self.running then
		data, msg_or_ip, port_or_nil = self.udp:receivefrom()
		if data then
			print(concat('Recieved client data:', data, "; from:", msg_or_ip, ":", port_or_nil))
			cmd = data---data:match("^(%S+) (%d+)")
			if cmd == "waiting" then
				print("client isn't doing anything")
			
			elseif cmd == "did a thing" then
				print("OMG CLIENT DID A THING")
				self.num = self.num + 1

			elseif cmd == "PLZ UPDATE" then
				print("client asked for update: *sends number*")
				local cmd = concat("number ", self.num)
				self.udp:sendto(cmd, msg_or_ip,  port_or_nil)

			elseif cmd == 'quit' then
				running = false;
			
			else
				print("unrecognised command:", cmd)
			end
		elseif msg_or_ip ~= 'timeout' then
			error("Unknown network error: "..tostring(msg))
		end
		
		socket.sleep(0.01)
	end
end

function Server:stop()
	self.running = false
	print "Server ended, thank you."
end

return Server