local socket = require "socket"
local Class = require "class"
local Board = require "board"
local font = require "font"
local img = require "images"
local sfx = require "sfx"

local udp = socket.udp()

local Server = Class:inherit()

function Server:init()
	self.running = true
	self.type = "server"

	-- Server properties
	self.name = "[SERVER]"
	
	print("----------------------")
	print("Beginning server loop.")

	self.interface = "*"--"0.0.0.0"--"*"
	self.port = 12345

	print(concat("Setting sock name: ", self.interface,",",self.port))
	udp:settimeout(0)
	udp:setsockname(self.interface, self.port)

	-- Clients
	self.number_of_clients = 0
	self.clients = {}
	self.last_id = 0

	-- Map
	local b = Board:new(self)
	self.board_w = b.w
	self.board_h = b.h
	self.tile_size = b.tile_size
	self.seed = love.math.random(-99999, 99999)
	
	self.game_begin = true

	-- Timer
	self.timer = 0
	self.max_timer = 5*60 --5*60 = 300

	-- Countdown (3,2,1,GO)
	self.do_countdown = false
	self.countdown_timer = 0
end

function Server:update(dt)
	local old_timer = self.timer
	self.timer = self.timer - dt

	-- Tick SFX on low timer
	if self.timer <= 30 and math.ceil(self.timer) ~= math.ceil(old_timer) then
		audio:play(sfx.tick)
	end

	local data, msg_or_ip, port_or_nil
	local entity, cmd, parms

	data, msg_or_ip, port_or_nil = udp:receivefrom()
	
	if data then
		print(concat('Recieved client data:', data, "; from: ", msg_or_ip, ":", port_or_nil))
		local cmd, parms = data:match("^(%S*) (.*)$")
		local ip, port = msg_or_ip, port_or_nil
		local socket = concat(msg_or_ip,":",port_or_nil)
		local client = self.clients[socket]

		-- Reset client timeout timer to 5 seconds (lenghthen if needed)
		if client then   client.timeout_timer = 5   end
		
		if cmd == "join" then
			-- User joins
			-- TODO: define users by ID rather than socket name
			local name = parms 
			self.last_id = self.last_id + 1
			local new_id = self.last_id
			-- If name is not defined, use default
			if not name or #name < 1 then  name="Personnecool_"..tostring(new_id)  end
			-- If usedrname is already taken, append the ID number
			if self:name_already_used(name) then  name=name..tostring(new_id)  end

			self.number_of_clients = self.number_of_clients + 1
			self.clients[socket] = {
				id = new_id,
				ip = msg_or_ip,
				port = port_or_nil,
				socket = socket,
				name = name,
				board = Board:new(self, self.seed, socket, 0.5, false),
				
				rank = 0,
				is_win = false,
				game_over = false,
				state = "",
				end_time = -1,

				timeout_timer = 5,
			}
			
			-- Notify the client with its new ID
			print("Assigning new id", new_id)
			udp:sendto(concat("assignid ",new_id), msg_or_ip, port_or_nil)

			print("Assigning new seed", self.seed)
			udp:sendto(concat("assignseed ",self.seed), msg_or_ip, port_or_nil)
			
			print("Assigning new name", name)
			udp:sendto(concat("assignname ",name), msg_or_ip, port_or_nil)
			
			-- Notify others with a chat message
			self:send_chat_message(concat("%y",name," a rejoint."))
			print(concat("Client joined, assigned ID :\"",new_id, "\" with name: \"",name,"\""))

		elseif cmd == 'leave' then
			-- User leaves
			if self.clients[socket] then
				local id = parms:match("^(%-?[%d.e]*)")
				local client = self.clients[socket]
				self:send_chat_message(concat("%y",client.name," a quitté."))
				print(concat("Player \"", client.name,"\" with IP ",socket," left."))
				
				self.number_of_clients = self.number_of_clients - 1
				self.clients[socket] = nil
			end

		elseif cmd == 'update' then
			-- Update client with their rank
			if client then
				local msg = concat("update ",client.rank)
				udp:sendto(msg, msg_or_ip,  port_or_nil)
			end
		
		elseif cmd == "listranks" then
			-- Update client with other players' rankings
			-- TODO: this might create strings that are too big and 
			-- saturate the network. Right now the cooldown is at 1
			-- seconds, change if it's needed, or split into multiple messages.
			if client then
				local msg = "listranks"
				for sock, client in pairs(self.clients) do
					local rank = client.rank
					local percentage = client.board.percentage_cleared
					local state = "none"
					if client.game_over then
						state = "game_over"
					elseif client.is_win then
						state = "win"
					end

					-- If it's itself, flag it by making the rank regative
					if client.socket == socket then   rank = -rank  end
					msg = concatsep({msg, client.name, rank, percentage, state}, " ")
				end
				udp:sendto(msg, msg_or_ip, port_or_nil)
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
			local set, tx, ty, is_valid = parms:match("^(.*) (%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
			set, tx, ty, is_valid = tobool(set), tonumber(tx), tonumber(ty), is_valid=="1"

			if self.clients[socket] and self.game_begin and is_valid then
				self.clients[socket].board:set_flag(tx, ty, set)
			end

		elseif cmd == "fastreveal" then
			local tx, ty, is_valid = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*) (%d)$")
			tx, ty, is_valid = tonumber(tx), tonumber(ty), is_valid=="1"

			local client = self.clients[socket]
			client.board:on_button3(tx, ty, is_valid)

		elseif cmd == "chat" then
			local msg = parms
			chat:new_msg(msg)
			-- Send chat message to all clients
			for s, client in pairs(self.clients) do
				if s ~= socket then
					udp:sendto("chat "..msg, client.ip, client.port)
				end
			end

		elseif cmd == "ping" then
			udp:sendto("chat %yServer: Pong!", msg_or_ip,  port_or_nil)

		elseif cmd == "rename" then
			local new_name = parms
			local old_name = self.clients[socket].name

			-- We check if there is already someone with this name
			local existing_client = self:get_user_from_name(new_name)
			if existing_client then
				new_name = new_name + tostring(self.last_id)
				self.last_id = self.last_id + 1
				udp:sendto("assignname "..new_name, ip, port)
			end

			self.clients[socket].name = new_name
			self:send_chat_message(concat("%y",old_name," s'est renommé à ",new_name))

		elseif "color" then
			if client then
				local color = parms
				local success, error_msg = client.board:set_tile_color(color)
				if error_msg then   print(concat("Error when trying to change color: \"",error_msg,"\""))   end
			end

		elseif cmd == "stop" then
			-- Stops the server.
			--self:stop()
		
		elseif cmd == "itemearthquake" then
			-- TEMPORARY REMOVEME <<<<<<<<<<<<<<<<<<
			local target_name = parms:match("(.*)")
			local target = self:get_user_from_name(target_name)

			if target then
				local seed = love.math.random(-99999,99999)
				local msg = concat("itemearthquake ",seed)
				target.board:item_earthquake(seed)
				udp:sendto(msg, target.ip, target.port)
			else
				notification("Error: invalid item target: \"",target_name,"\"")
			end

		else
			print("unrecognised command:", cmd)
		end
	elseif msg_or_ip ~= 'timeout' then
		error("Unknown network error: "..tostring(msg))
	end

	self:assign_ranks_to_players()
	-- Update all boards
	for socket,client in pairs(self.clients) do
		client.board:update(dt)
	end

	-- If timer reaches 0, notify all clients that the game has ended
	if self.game_begin and self.timer <= 0 then
		self:stop_game()
	end
	-- If all players are waiting (lost or won), stop the game
	if self.game_begin and self:check_if_all_players_waiting() then
		self:stop_game()
	end

	self:update_clients(dt)

	-- 3, 2, 1, GO
	self:update_countdown_timer()

	socket.sleep(0.01)
end

function Server:draw()
	if self.number_of_clients > 0 then
		self:draw_clients()
	else -- If no client is connected
		draw_centered_text("Aucun joueur (-.-) . zZZ", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
	end
	
	-- Particles
	particles:draw()

	if self.game_begin then
		-- Display timer
		self:draw_time()
		-- Last seconds display
		local time = math.ceil(self.timer)
		if tonumber(self.timer) <= 10 and not self.is_waiting then
			love.graphics.setFont(font.regular_huge)
			love.graphics.setColor(1,1,1,0.3)
			draw_centered_text(time, 0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
			love.graphics.setColor(1,1,1)
			love.graphics.setFont(font.regular)
		end
	else 
		-- If the game hasn't begun, draw waiting screen
		self:draw_waiting_screen()
	end

	chat:draw()
end

function Server:update_clients(dt)
	for sock, client in pairs(self.clients) do
		client.timeout_timer = client.timeout_timer - dt
		if client.timeout_timer < 0 then
			self:kick_user(client.name, concat("%y",client.name," a été expulsé car le serveur ne reçevait plus de réponse \\(·.·)/"))
		end
	end
end

function Server:keypressed(key)
	if chat.display_chat then
		-- Do not do buttons if in chat input mode
		return
	end

	if key == "s" then
		if love.keyboard.isDown("lshift") then
			self:begin_game()
		else
			self:begin_countdown()
		end
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

function Server:begin_countdown()
	self.do_countdown = true
	self.countdown_timer = 3
	self.stats = {}
	audio:play(sfx.tick)

	local msg = concat("begincount server")
	for socket,client in pairs(self.clients) do
		udp:sendto(msg, client.ip, client.port)
	end
end

function Server:update_countdown_timer()
	if self.do_countdown then
		local dt = love.timer.getDelta()
	
		local oldtimer = self.countdown_timer 
		self.countdown_timer = self.countdown_timer - dt
		
		-- "clock tick" SFX
		if math.ceil(self.countdown_timer) ~= math.ceil(oldtimer) then
			audio:play(sfx.tick)
		end

		if self.countdown_timer < -0.5 then
			self.do_countdown = false
			self:begin_game()
		end
	end
end

function Server:draw_countdown()
	if self.do_countdown then
		love.graphics.setColor(0,0,0,0.8)
		love.graphics.rectangle("fill", 0,0, WINDOW_WIDTH, WINDOW_HEIGHT)
		
		love.graphics.setColor(1,1,1,1)
		local count = math.ceil(self.countdown_timer)
		if self.countdown_timer > 0 then
			draw_centered_text(tostring(count), 0,0, WINDOW_WIDTH, WINDOW_HEIGHT, 0,1,1, font.regular_huge)
		else
			draw_centered_text("GO!", 0,0, WINDOW_WIDTH, WINDOW_HEIGHT, 0,1,1, font.regular_huge)
		end
	end
end



function Server:begin_game()
	-- Stop countdown
	self.do_countdown = false

	-- Notify all connected client that the game has begun, with time and seed 
	self.game_begin = true
	self.timer = self.max_timer
	self.seed = love.math.random(-99999,99999)

	local msg = concat("begingame ",self.max_timer," ",self.seed)
	for socket,client in pairs(self.clients) do
		udp:sendto(msg, client.ip, client.port)

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
		udp:sendto(msg, client.ip, client.port)
	end
end

function Server:quit()
	for socket, client in pairs(self.clients) do
		udp:sendto("quit 123", client.ip, client.port)
	end
end

function Server:stop()
	self.running = false
	print "Server stopped, thank you."
	self:quit()
	love.event.quit()
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

		-- Display player name 
		love.graphics.setColor(1,1,1)
		love.graphics.print(client.name, x+48, y-32)
		
		-- Number of flags
		--love.graphics.draw(img.flag, x+board_width-64, y-32)
		--love.graphics.print(client.board.remaining_flags, x+board_width-32, y-32)
		
		-- Percentage cleared
		local text = concat(client.board.percentage_cleared,"%")
		local text_x = x+board_width - get_text_width(text)
		local percent_x = text_x - 32
		love.graphics.draw(img.shovel, percent_x, y-32)
		love.graphics.print(text, text_x, y-32)
		
		-- Display current rank
		draw_rank_medal(client.rank, {.2,.2,.2}, x, y-32)
		love.graphics.setColor(1,1,1)
		
		-- Draw game over/win
		if client.game_over or client.is_win then
			local text = ""
			local icon = img.square
			if client.game_over then
				text = "Perdu!"
				icon = img.skull

			elseif client.is_win then
				text = "Victoire"
				icon = img.crown

			end

			local center_x, center_y = x+board_width/2, y+board_height/2
			love.graphics.setColor(0,0,0, 0.7)
			love.graphics.rectangle("fill", x, y, board_width, board_height)
			love.graphics.setColor(1,1,1)
			draw_centered_text(text, x,y, board_width, board_height)
			love.graphics.draw(icon, center_x-16, center_y-48)
			-- Time
			local time = tostring(math.floor(self.max_timer - client.end_time))
			local w = get_text_width(time) + 32+8
			local time_x = math.floor(center_x-w/2)
			love.graphics.draw(img.clock, time_x, center_y+32)
			love.graphics.print(time, time_x + 32+8, center_y+32, 0, 0.8)
		end

		i=i+1
	end
end

function Server:draw_time()
	local x,y = WINDOW_WIDTH/2, 128--WINDOW_HEIGHT/4
	-- Circle
	love.graphics.setColor(0,0,0,.5)
	love.graphics.circle("fill", x, y, 64)

	-- Flash text in red if less than 30 secs
	love.graphics.setColor(1,1,1)
	if self.timer <= 30 and self.timer%1 < .5 then   love.graphics.setColor(1,0,0)   end
	-- Clock icon
	love.graphics.draw(img.clock, x, y-42, 0,1,1, 16,16)
	love.graphics.setFont(font.regular_big)
	-- Timet text
	local t = math.max(0, math.ceil(self.timer))
	print_centered(t, x, y+16)
	love.graphics.setFont(font.regular)
end

function Server:draw_waiting_screen()
	local w,h = WINDOW_WIDTH, 64
	local x,y = (WINDOW_WIDTH-w)/2, 64

	-- XX joueurs connectés
	love.graphics.setColor(0,0,0,.7)
	love.graphics.rectangle("fill",x,y,w,h)
	love.graphics.setColor(1,1,1)
	local s = self.number_of_clients<=1 and "" or "s"
	local txt = concat(self.number_of_clients," joueur",s," connecté",s,".")
	
	draw_centered_text(txt, x,y,w,h)
	love.graphics.setColor(.5,.5,.5)
	draw_centered_text("Appuyez sur 'S' pour démarrer la partie.",x,y,w,h+100,0,0.8)
	
	-- Countdown timer (3, 2, 1, GO!)
	self:draw_countdown()

	love.graphics.setColor(1,1,1)
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

function Server:name_already_used(name)
	for s,client in pairs(self.clients) do
		if client.name == name then
			return true
		end
	end
	return false
end

function Server:get_user_from_name(name)
	for s,client in pairs(self.clients) do
		if client.name == name then
			return client
		end
	end
	return nil
end

function Server:send_to_all_clients(msg)
	--TODO: this might saturate the network if people spam
	for s,client in pairs(self.clients) do
		udp:sendto(msg, client.ip, client.port)
	end
end

function Server:on_new_chat_msg(msg)
	self:send_to_all_clients(concat("chat ",msg))
end

function Server:send_chat_message(msg, except)
	chat:new_msg(msg)
	for s, client in pairs(self.clients) do
		if s ~= except then
			udp:sendto("chat "..msg, client.ip, client.port)
		end
	end
end

function Server:sendto(msg, name)
	local user = self:get_user_from_name(name)
	udp:sendto("chat "..tostring(msg), user.ip, user.port)
end

function Server:kick_user(username, msg)
	local user = self:get_user_from_name(username)
	--if sock then   user = self.clients[sock]   end
	msg = msg or concat("%y",username," a été renvoyé de la partie.")

	if user then
		self.number_of_clients = self.number_of_clients - 1
		self:send_chat_message(msg, user.socket)
		self:sendto("%yVous avez été renvoyé de la partie D:", username)
		udp:sendto("kick 123", user.ip, user.port)

		self.clients[user.socket] = nil
	else
		chat:new_msg("%rErreur: pas de joueur sous le nom \""..username.."\"")
	end
end

return Server