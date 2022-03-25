local socket = require "socket"
local Class = require "class"
local Board = require "board"

local Server = Class:inherit()

function Server:init()
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
			local socket = concat(msg_or_ip,":",port_or_nil)
			
			if cmd == "join" then
				-- User joins
				local name = parms
				local new_id = self.number_of_clients + 1
				if not name or #name <= 1 then  name="user_n°"..tostring(new_id)  end
				self.number_of_clients = self.number_of_clients + 1
				self.clients[socket] = {
					id = new_id,
					name = name,
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
				
				if self.clients[socket] then
					self.clients[socket].board:on_button1(tx, ty, is_valid)
				end

			elseif cmd == "flag" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"

				if self.clients[socket] then
					self.clients[socket].board:on_button2(tx, ty, is_valid)
				end

			elseif cmd == "ping" then
				self.udp:sendto("pong!", msg_or_ip,  port_or_nil)

			elseif cmd == 'leave' then
				-- User leaves
				local id = parms:match("^(%-?[%d.e]*)")
				self.number_of_clients = self.number_of_clients - 1
				self.clients[socket] = nil
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
		local spacing = 32
		local scale = 0.5

		local board_width = self.board_w * self.tile_size * scale
		local board_height = self.board_h * self.tile_size * scale
		local total_board_width = (board_width + spacing)
		local total_board_height = (board_height + spacing)
		local overflow_max = math.floor(WINDOW_WIDTH / total_board_width)

		local w = math.min(self.number_of_clients, overflow_max)
		local total_width = (w * total_board_width) - spacing
		local h = math.floor((self.number_of_clients / overflow_max) - 0.01)
		local total_height = (h * total_board_height) - spacing

		local ox = (WINDOW_WIDTH - total_width) / 2
		local oy = (WINDOW_HEIGHT - total_height) / 2 - board_height/2

		local i = 0
		for socket,client in pairs(self.clients) do
			local x = ox +           (i % overflow_max) * total_board_width
			local y = oy + math.floor(i / overflow_max) * total_board_height

			-- Draw board
			client.board.x = x
			client.board.y = y
			client.board.scale = 0.5
			client.board:draw()
			love.graphics.print(client.name, x, y-32)

			-- Draw game over/win
			if client.board.game_over then
				love.graphics.setColor(0,0,0, 0.7)
				love.graphics.rectangle("fill", x, y, board_width, board_height)
				love.graphics.setColor(1,1,1)
				draw_centered_text("Perdu !", x,y, board_width, board_height)
			end
			if client.board.is_win then
				love.graphics.setColor(1,1,1, 0.7)
				love.graphics.rectangle("fill", x, y, board_width, board_height)
				love.graphics.setColor(1,1,1)
				draw_centered_text("Victoire !", x,y, board_width, board_height)
			end

			i=i+1
		end

		--love.graphics.print(concat(self.number_of_clients," clients connected"), 5,5)
	else
		draw_centered_text("Aucun client :(", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	end	
end

function Server:stop()
	self.running = false
	print "Server stopped, thank you."
end

return Server