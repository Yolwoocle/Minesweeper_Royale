local socket = require "socket"
local Class = require "class"
local Board = require "board"
local font = require "font"
local img = require "images"

local Server = Class:inherit()

function Server:init()
	print("----------------------")
	print("Beginning server loop.")

	self.interface = "0.0.0.0" --"*"
	self.port = 12345

	print(concat("Setting sock name: ", self.interface,",",self.port))
	self.udp = socket.udp()
	self.udp:settimeout(0)
	self.udp:setsockname(self.interface, self.port)

	self.num = 100
	self.running = true

	self.number_of_clients = 0
	self.clients = {}

	self.message_queue = {}

	local b = Board:new(self)
	self.board_w = b.w
	self.board_h = b.h
	self.tile_size = b.tile_size

	self.seed = love.math.random(-30000, 30000)

	self.game_begin = false
	self.timer = 0
	self.max_timer = 5*60 --5*60 = 300
end

function Server:update(dt)
	self.timer = self.timer - dt

	local data, msg_or_ip, port_or_nil
	local entity, cmd, parms

	if self.running then
		data, msg_or_ip, port_or_nil = self.udp:receivefrom()
		
		if data then
			--print(concat('Recieved client data:', data, "; from:", msg_or_ip, ":", port_or_nil))
			local cmd, parms = data:match("^(%S*) (.*)$")
			local socket = concat(msg_or_ip,":",port_or_nil)
			local client = self.clients[socket] 
			
			if cmd == "join" then
				-- User joins
				local name = parms
				local new_id = self.number_of_clients + 1
				if not name or #name <= 1 then  name="user_n°"..tostring(new_id)  end
				self.number_of_clients = self.number_of_clients + 1
				self.clients[socket] = {
					id = new_id,
					ip = msg_or_ip,
					port = port_or_nil,
					name = name,
					board = Board:new(self, self.seed, socket),
					
					rank = 0,
					is_win = false,
					game_over = false,
					state = "",
					end_time = -1,
				}
				notification(name," a rejoint.")
				print(concat("Client joined, assigned ID :\"",new_id, "\" with name: \"",name,"\""))
				
				-- Notify the client with its new ID
				print("Assigning new id", new_id)
				self.udp:sendto(concat("assignid ",new_id), msg_or_ip, port_or_nil)
				print("Assigning new seed", self.seed)
				self.udp:sendto(concat("assignseed ",self.seed), msg_or_ip, port_or_nil)

			elseif cmd == 'leave' then
				-- User leaves
				if self.clients[socket] then
					local id = parms:match("^(%-?[%d.e]*)")
					local client = self.clients[socket]
					notification(client.name," a quitté.")
					print(concat("Player \"", client.name,"\" with IP ",socket," left."))
					
					self.number_of_clients = self.number_of_clients - 1
					self.clients[socket] = nil
				end

			elseif cmd == 'update' then
				-- Update client
				if client then
					local msg = concat("update ",client.rank)
					self.udp:sendto(msg, msg_or_ip,  port_or_nil)
				end

			elseif cmd == "break" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"
				
				if self.clients[socket] and self.game_begin then
					self.clients[socket].board:on_button1(tx, ty, is_valid)
				end

			elseif cmd == "flag" then
				-- Client breaks tile
				local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
				tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"

				if self.clients[socket] and self.game_begin then
					self.clients[socket].board:on_button2(tx, ty, is_valid)
				end

			elseif cmd == "ping" then
				self.udp:sendto("pong!", msg_or_ip,  port_or_nil)


			elseif cmd == 'stop' then
				self:stop()
			
			else
				print("unrecognised command:", cmd)
			end
		elseif msg_or_ip ~= 'timeout' then
			error("Unknown network error: "..tostring(msg))
		end

		self:assign_ranks_to_players()
		-- Update all boards
		for socket,client in pairs(self.clients) do
			client.board:update()
		end

		-- If timer reaches 0, notify all clients that the game has ended
		if self.game_begin and self.timer <= 0 then
			self:stop_game()
		end
		-- If all players are waiting (lost or won), stop the game
		if self.game_begin and self:check_if_all_players_waiting() then
			self:stop_game()
		end

		socket.sleep(0.01)
	end
end

function Server:draw()
	if self.number_of_clients > 0 then
		self:draw_clients()
	else -- If no client is connected
		draw_centered_text("Aucun joueur (-.-) . zZZ", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	end
	
	if self.game_begin then
		-- Display timer
		self:draw_time()
	else 
		-- If the game hasn't begun, draw waiting screen
		self:draw_waiting_screen()
	end
end

function Server:keypressed(key)
	if key == "s" then
		self:begin_game()
	end
end

function Server:on_game_over(socketname)
	self.clients[socketname].state = "lose"
	self.clients[socketname].game_over = true
	self.clients[socketname].end_time = self.timer
end
function Server:on_win(socketname)
	self.clients[socketname].state = "win"
	self.clients[socketname].is_win = true
	self.clients[socketname].end_time = self.timer
end

function Server:begin_game()
	-- Notify all connected client that the game has begun, with time and seed 
	self.game_begin = true
	self.timer = self.max_timer
	self.seed = love.math.random(-30000,30000)

	local msg = concat("begingame ",self.max_timer," ",self.seed)
	for socket,client in pairs(self.clients) do
		self.udp:sendto(msg, client.ip, client.port)

		client.state = ""
		client.rank = 0
		client.is_win = false
		client.game_over = false
		client.end_time = -1

		client.board:reset()
		client.board.seed = self.seed
	end
end

function Server:stop_game()
	-- Notify all clients that the game has ended
	self.game_begin = false

	local msg = concat("stopgame 123")
	for socket,client in pairs(self.clients) do
		self.udp:sendto(msg, client.ip, client.port)
	end
end

function Server:quit()
	for socket, client in pairs(self.clients) do
		self.udp:sendto("quit 123", client.ip, client.port)
	end
end

function Server:stop()
	self.running = false
	print "Server stopped, thank you."
end

function Server:draw_clients()
	-- Display all clients
	local spacing = 32
	local scale = 0.5

	-- Compute board dimensions & offsets
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
		-- Display name & number of flags
		love.graphics.setColor(1,1,1)
		love.graphics.print(client.name, x+36, y-32)
		love.graphics.draw(img.flag, x+board_width-64, y-32)
		love.graphics.print(client.board.remaining_flags, x+board_width-32, y-32)
		-- Display current rank
		local rank_col = get_rank_color(client.rank, {.2,.2,.2})
		love.graphics.setColor(rank_col)
		love.graphics.draw(img.circle, x, y-32)
		love.graphics.setColor(1,1,1)
		print_centered(client.rank, x+16, y-16)
		local e = client.rank==1 and "er" or "e"
		print_centered(e, x+38, y-16, 0, .5)

		love.graphics.setColor(1,1,1)
		
		-- Draw game over/win
		if client.game_over then
			love.graphics.setColor(0,0,0, 0.7)
			love.graphics.rectangle("fill", x, y, board_width, board_height)
			love.graphics.setColor(1,1,1)
			draw_centered_text("Perdu !", x,y, board_width, board_height)

		elseif client.is_win then
			love.graphics.setColor(0,0,0, 0.7)
			love.graphics.rectangle("fill", x, y, board_width, board_height)
			love.graphics.setColor(1,1,1)
			draw_centered_text("Victoire !", x,y, board_width, board_height)
		end

		i=i+1
	end
end

function Server:draw_time()
	local x,y = WINDOW_WIDTH/2, WINDOW_HEIGHT/4
	love.graphics.setColor(0,0,0,.5)
	love.graphics.circle("fill", x, y, 64)
	love.graphics.setColor(1,1,1)
	love.graphics.draw(img.clock, x, y-42, 0,1,1, 16,16)
	love.graphics.setFont(font.regular_big)
	local t = math.max(0, math.ceil(self.timer))
	print_centered(t, x, y+16)
	love.graphics.setFont(font.regular)
end

function Server:draw_waiting_screen()
	local w,h = WINDOW_WIDTH, 64
	local x,y = (WINDOW_WIDTH-w)/2, 64
	love.graphics.setColor(0,0,0,.7)
	love.graphics.rectangle("fill",x,y,w,h)
	love.graphics.setColor(1,1,1)
	local s = self.number_of_clients<=1 and "" or "s"
	local txt = concat(self.number_of_clients," joueur",s," connecté",s,". Appuyez sur 'S' pour démarrer la partie.")
	draw_centered_text(txt, x,y,w,h)
end

function Server:check_if_all_players_waiting()
	for socket,client in pairs(self.clients) do
		local waiting = (client.board.game_over or client.board.is_win)
		if not waiting then
			return false
		end
	end
	return true
end

function Server:assign_ranks_to_players()
	local players = {}
	for sock,client in pairs(self.clients) do
		client.number_of_open_tiles = client.board:get_number_of_open_tiles()
		table.insert(players, client)
	end

	table.sort(players, function(a,b)
		-- "Should a be in front of b?"
		local an, bn = a.number_of_open_tiles, b.number_of_open_tiles
		if an ~= bn then
			return an > bn
		else
			-- If both players have broken the same number of tiles
			return a.end_time > b.end_time
		end
	end)

	-- Assign rank to referenced objects
	for rank,player in ipairs(players) do
		player.rank = rank
	end

	-- Check for equality
	for i=1, #players-1 do
		local a, b = players[i], players[i+1]
		local an, bn = a.number_of_open_tiles, b.number_of_open_tiles
		if an == bn and a.end_time == b.end_time then
			b.rank = a.rank
		end
	end
end

return Server