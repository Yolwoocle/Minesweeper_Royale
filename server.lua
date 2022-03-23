local socket = require "socket"
local Class = require "class"
local Board = require "board"

local Server = Class:inherit()

function Server:init(game)
	self.game = game

	self.udp = socket.udp()
	self.udp:settimeout(0)
	self.udp:setsockname('*', 12345)

	self.num = 100
	self.running = true

	self.number_of_clients = 0
	self.clients = {}

	local b = Board:new()
	self.board_w = b.w
	self.board_h = b.h
	self.tile_size = b.tile_size

	self.seed = love.math.random(-10000, 10000)

	print "Beginning server loop."
end

function Server:update(dt)
	local data, msg_or_ip, port_or_nil
	local entity, cmd, parms

	if self.running then
		data, msg_or_ip, port_or_nil = self.udp:receivefrom()
		
		if data then
			print(concat('Recieved client data:', data, "; from:", msg_or_ip, ":", port_or_nil))
			local cmd, parms = data:match("^(%S*) (.*)$")
			local address = concat(msg_or_ip,":",port_or_nil)
			
			if cmd == "join" then
				-- User joins
				local new_id = self.number_of_clients + 1
				self.number_of_clients = self.number_of_clients + 1
				self.clients[address] = {
					id = new_id,
					name = "user_n°"..tostring(new_id),
					board = Board:new(self.seed),
					ip = msg_or_ip,
					port = port_or_nil,
				}
				print(concat("Client joined, assigned ID :",new_id))
				-- Notify the client with its new ID
				self.udp:sendto(concat("assignid ",new_id), msg_or_ip, port_or_nil)
				self.udp:sendto(concat("assignseed ",self.seed), msg_or_ip, port_or_nil)
				print("self.seed:", self.seed)

			elseif cmd == "break" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"
				
				self.clients[address].board:on_button1(tx, ty, is_valid)
				
			elseif cmd == "flag" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"

				self.clients[address].board:on_button2(tx, ty, is_valid)
				
			elseif cmd == "PLZ UPDATE" then
				print("client asked for update: sending number:", self.num)
				local cmd = concat("number ", self.num)
				self.udp:sendto(cmd, msg_or_ip,  port_or_nil)

			elseif cmd == 'leave' then
				-- User leaves
				local id = parms:match("^(%-?[%d.e]*)")
				self.number_of_clients = self.number_of_clients - 1
				self.clients[id] = nil
				print(concat("Player with id ",id," left."))

			elseif cmd == 'stop' then
				self:stop()
			
			else
				print("unrecognised command:", cmd)
			end
		elseif msg_or_ip ~= 'timeout' then
			error("Unknown network error: "..tostring(msg))
		end
		
		socket.sleep(0.01)
	end
end

function Server:draw()
	if self.number_of_clients > 0 then
		-- Display all clients
		local spacing = 16

		local board_width = self.board_w * self.tile_size
		local board_height = self.board_h * self.tile_size
		local overflow_max = math.floor(WINDOW_WIDTH / (board_width + spacing))

		local i = 0
		for address,client in pairs(self.clients) do
		draw_centered_text("At least one client :D", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)

			local x =           (i % overflow_max) * (board_width + spacing)
			local y = math.floor(i / overflow_max) * (board_height + spacing)

			client.board.x = x
			client.board.y = y
			client.board:draw()

			i=i+1
		end
	else
		draw_centered_text("No clients :(", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	end	
end

function Server:stop()
	self.running = false
	print "Server stopped, thank you."
end

return Server