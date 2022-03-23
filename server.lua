local socket = require "socket"
local Class = require "class"

local Server = Class:inherit()

function Server:init(game)
	self.game = game

	self.udp = socket.udp()
	self.udp:settimeout(0)

	self.udp:setsockname('*', 12345)

	self.num = 100
	self.running = true

	self.clients = {}
	
	print "Beginning server loop."
end

function Server:update(dt)
	local data, msg_or_ip, port_or_nil
	local entity, cmd, parms

	if self.running then
		data, msg_or_ip, port_or_nil = self.udp:receivefrom()
		if data then
			print(concat('Recieved client data:', data, "; from:", msg_or_ip, ":", port_or_nil))
			local cmd, parms = data:match("^(%S+) (.*)")
			
			if cmd == "join" then
				local new_id = #self.clients + 1
				self.clients[new_id] = {
					id = new_id,
					name = "user_n°"..tostring(new_id),
					ip = msg_or_ip,
					port = port_or_nil,
				}
				print(concat("Client joined, assigned ID :",new_id))
			
			elseif cmd == "break" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"
				self.game:on_button1(tx, ty, is_valid)
				print("client broke a tile")

			elseif cmd == "PLZ UPDATE" then
				print("client asked for update: sending number")
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