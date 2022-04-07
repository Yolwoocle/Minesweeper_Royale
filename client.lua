local socket = require "socket"
local Class = require "class"
local Board = require "board"
local font = require "font"
local img = require "images"

local udp = socket.udp()

local Client = Class:inherit()
function Client:init()
	self.game_begin = false
	self.is_waiting = true
	self.waiting_msg = ""

	self.is_win = false
	self.board = Board:new(self)
	self.name = self:get_name()
	love.window.setTitle("Minesweeper Royale - "..self.name)

	-- Networking
	self:init_socket()

	self.timer = 0

	self.rank = 0
	self.ranking_request_timer = 0
	self.max_ranking_request_timer = 1 --Ask for other people's rank every ? seconds
	self.rankings = {}

	self.number_of_broken_tiles = 0
end

function Client:init_socket()
	print("Client started")
	self.is_connected = false
	self.network_error = ""
	self.waiting_msg = "Connection au serveur..."

	--Which IP in the serverip.txt file the client is connected to
	self.fallback_number = 1
	self.fallback_servers = self:read_server_ips()
	local default_serv = self.fallback_servers[1]
	
	self.address = default_serv.ip or "localhost"
	self.port = default_serv.port or 12345
	print("Set address and port to default "..self.address..":"..tostring(self.port))

	-- How long to wait, in seconds, before requesting an update
	self.updaterate = 0.1 

	udp:settimeout(0)

	print("Attempting connection to server")
	self:join_server(self.address, self.port, default_serv.name)
	
	self.message_queue = {}
	self.t = 0 

	self.do_timeout = true
	self.timeout_timer = 0
	self.timeout_max = 5
end

function Client:update(dt)
	if self.is_waiting then

	else	
		self.timer = self.timer - dt
	end

	self.board:update(dt)
	self:update_socket(dt)
end

function Client:draw()
	-- Display board
	self.board:draw(self.game_begin)
	-- Draw particles
	particles:draw()

	-- Ui (counters, etc)
	self:draw_ui()

	-- Display waiting messages
	if self.is_waiting then
		love.graphics.setColor(0,0,0, .6)
		love.graphics.rectangle("fill",0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
		love.graphics.setColor(1,1,1)
		draw_centered_text(self.waiting_msg, 0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
	end

	-- Display any network errors
	if #self.network_error > 0 then
		draw_centered_text("Erreur: \""..self.network_error.."\"", 0,0, WINDOW_WIDTH,64)
	end
end

function Client:draw_ui()
	local x, y = self.board.x, self.board.y-32

	-- Display score
	--love.graphics.draw(img.shovel_big, x, y-16)
	--love.graphics.setFont(font.regular_32) 
	--love.graphics.print(tostring(self.board.percentage_cleared).."%", x+42+8, y-8)
	--love.graphics.setFont(font.regular)

	-- Clock & timer
	local dx = x + self.board.tile_size*4
	local time = clamp(0, math.ceil(self.timer),99999)
	-- Flash text in red if less than 30 secs
	love.graphics.setColor(1,1,1)
	if self.timer <= 30 and self.timer%1 > .5 then   love.graphics.setColor(1,0,0)   end
	-- Icon & text
	love.graphics.draw(img.clock, dx, y)
	love.graphics.print(time, dx+32, y)

	-- Display number of remaining flags
	love.graphics.setColor(1,1,1)
	local flag_x = x + self.board.tile_size*7
	local n_flags = self.board.remaining_flags
	love.graphics.draw(img.flag, flag_x, y)
	love.graphics.print(n_flags, flag_x+32, y)

	-- Draw other players' rankings
	local dx = x + (self.board.w+1) * self.board.tile_size
	self:draw_player_rankings(dx, y)

	-- Display score
	love.graphics.draw(img.shovel_big, x, y-16)
	love.graphics.setFont(font.regular_32) 
	love.graphics.print(tostring(self.board.percentage_cleared).."%", x+42+8, y-8)
	love.graphics.setFont(font.regular)

	-- Last seconds display
	if tonumber(self.timer) <= 10 and not self.is_waiting then
		love.graphics.setFont(font.regular_huge)
		love.graphics.setColor(1,1,1,0.3)
		draw_centered_text(time, 0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
		love.graphics.setColor(1,1,1)
		love.graphics.setFont(font.regular)
	end
end

function Client:mousepressed(x,y,button)	
	local tx, ty, isclicked, is_valid = self.board:get_selected_tile()
	if button == 1 then
		self:on_button1(tx, ty, is_valid)
	elseif button == 2 then
		self:on_button2(tx, ty, is_valid)
	end
end

function Client:on_button1(tx, ty, is_valid)
	if self.board.on_button1 and not self.is_waiting then  
		local broken = self.board:on_button1(tx, ty, is_valid)  
		
		if broken then
			-- Prepare network package for later
			self:queue_request("break", tx," ",ty," ",bool_to_int(is_valid))
		end
	end

end

function Client:on_button2(tx, ty, is_valid)
	local placed_flag
	if is_valid and not self.is_waiting then  
		placed_flag = self.board:toggle_flag(tx, ty)

		--response = self.board:on_button2(tx, ty, is_valid)  
	end

	if placed_flag ~= nil then
		-- Prepare network package for later
		self:queue_request_set_flag(placed_flag, tx, ty, is_valid)
	end
end

function Client:queue_request_set_flag(val, tx, ty, is_valid)
	table.insert(self.message_queue, {
		"flag", concat(val," ",tx," ",ty," ",bool_to_int(is_valid))
	})
end

function Client:queue_request(cmd, ...)
	table.insert(self.message_queue, {
		cmd, concat(...)
	})
end

function Client:keypressed(key)
	if key == "w" and #self.rankings > 1 then
		local randply = self:get_random_player()
		notification("TEST envoyer rafale ",randply)--REMOVEME
		self:queue_request("itemearthquake", randply)
	end
end

function Client:update_socket(dt)
	-- Update timer
	self.t = self.t + dt 
	if self.do_timeout then
		self.timeout_timer = self.timeout_timer + dt
	end

	-- If not connected and timeout time ran out, try another server
	if not self.is_connected and self.timeout_timer > self.timeout_max then
		if self.fallback_number <= #self.fallback_servers then
			-- Attempt to connect to fallback servers defined in the `serverip.txt` file
			self.timeout_timer = 0
			local curserv = self.fallback_servers[self.fallback_number]
			print("Attempting next fallback server: number",self.fallback_number+1)
			notification("Impossible de se connecter à \"",curserv.name,"\"")
			self:attempt_next_connection()
		
		else
			-- If all fallback servers have been tried
			self.timeout_timer = 0
			self.do_timeout = false
			notification("Impossible de se connecter au serveur.")
			notification("Merci de contacter l'administrateur.")
			self.waiting_msg = "Connection impossible, contactez l'administrateur"
		end
	end

	-- Send packets to the server every n seconds (default 1/30)
	if self.t > self.updaterate then
		local msg 
		if #self.message_queue > 0 then
			local q = self.message_queue[1]
			msg = tostring(q[1]).." "..tostring(q[2])
			table.remove(self.message_queue, 1)
		end
	
		-- Send the packet
		if msg then
			self:send(msg)	
		end

		-- Request for updates
		--local dg = "update 123"
		--self:send(dg)
		
		-- Set t for the next round
		self.t = self.t - self.updaterate 
	end

	-- If the game has started...
	if self.game_begin then
	end
	-- Request the server for other people's rankings
	self:request_for_rankings()

	-- Fetch all messages (there could be multiple!)
	repeat --...until not data
		local data, msg = udp:receive()
		
		-- Receive data from server
		if data then 
			self.is_connected = true
			self.network_error = ""
			local cmd, parms = data:match("^(%S*) (.*)$")
			if cmd ~= "update" then  print("Received server data:", data)  end

			if cmd == 'assignid' then
				self.id = tonumber(parms)
				self.waiting_msg = MSG_PLEASE_WAIT_SERVER
				notification(MSG_CONNECTION_ESTABLISHED_WITH_SERVER)

			elseif cmd == 'assignname' then
				self.name = parms
				love.window.setTitle("Minesweeper Royale - "..self.name)

			elseif cmd == "assignseed" then
				local seed = parms:match("^(%-?[%d.e]*)$")
				seed = tonumber(seed)
				self.board.seed = seed

--[[			elseif cmd == "assign" then
				local id, name, seed = parms:match("^(%-?[%d.e]*) (.*) (%-?[%d.e]*)$")
				seed = tonumber(seed)
				self.board.seed = seed
--]]
			elseif cmd == "update" then
				local rank = parms:match("^(%-?[%d.e]*)$")
				self.rank = tonumber(rank)

			elseif cmd == "begingame" then
				local max_timer, seed = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
				max_timer, seed = tonumber(max_timer), tonumber(seed)
				self:begin_game(max_timer, seed)
			
			elseif cmd == "stopgame" then
				self.game_begin = false
				self.is_waiting = true
				self.waiting_msg = MSG_GAME_ENDED_PLEASE_WAIT_FOR_ADMIN
				print("Game ended. GG!")

			elseif cmd == "listranks" then
				-- Update other player's ranks
				local ranks = split_str(parms, LISTRANKS_SEP) --use '&' as separator
				self.rankings = {}
				for i=1, #ranks, 3 do
					local name, rank, percentage = ranks[i], ranks[i+1], ranks[i+2]
					rank, percentage = tonumber(rank), tonumber(percentage)
					rank = rank or 0

					-- If the rank is negative, then the player is itself
					local is_self = false
					if rank < 0 then 
						rank = math.abs(rank)
						is_self = true
						
						-- Update the player's own rank
						self.rank = rank
					end

					table.insert(self.rankings, {
						name=name, 
						rank=rank,
						is_self=is_self,
						percentage=percentage,
					})
				end
				-- Sort ranks
				table.sort(self.rankings, function(a,b)  return a.rank < b.rank  end)

			elseif cmd == "itemearthquake" then
				local seed = parms:match("^(%-?[%d.e]*)$")
				seed = tonumber(seed)
				self.board:item_earthquake(seed)

			elseif cmd == "quit" then
				notification(MSG_SERVER_STOPPED_OR_RESTARTED)
				notification(MSG_PRESS_F5_TO_RESTART)

			elseif cmd == "chat" then
				local msg = parms
				chat:new_msg(msg)

			else
				print("Unrecognised server command:", cmd)
			end
		
		-- If data was nil, msg will contain a description of the problem
		-- while trying to recieve server data
		elseif msg ~= 'timeout' then 

			print(concat("ERROR: ", msg))
			self.is_connected = false

			if msg ~= self.waiting_msg then  
				notification(string.format("%s \"%s\"", MSG_ERROR_COLON, msg))
			end
			--self.waiting_msg = msg

			-- If the conenction was refused, attempt next server
			if msg == "connection refused" then
				print("Attempting next fallback server")
				self.timeout_timer = 0
				self:attempt_next_connection()
			else
				notification("Network error: "..tostring(msg))
			end

		end
	until not data 
end

function Client:read_server_ips(default)
	-- Generate list of fallback servers from the `serverip.txt` file
	-- The format is the following:
	-- ip [customNameWithoutSpaces] []

	-- [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+

	local ips = {}
	
	local local_ip = self:get_local_ip()
	table.insert(ips, {ip=local_ip, name=MSG_LOCAL_NETWORK})

	--table.insert(ips, {ip="0.0.0.0", name="Réseau local"})
	for line in love.filesystem.lines("serverip.txt") do
		if string.sub(line,1,1) ~= "#" then
			-- Split the string
			local s = split_str(line, " ")
			local ip, name, port = s[1], s[2], s[3]
			name = name or tostring(ip)
			port = port or 12345
			port = tonumber(port)

			if #name == 0 then  name = ip  end
			print(concat("New server: ip ",ip,"; name ",name,"; port ",port))
			table.insert(ips, {ip=ip, name=name})
		
		end
	end
	-- Try localhost as last
	--table.insert(ips, {ip="localhost", name="localhost"})

	return ips
end

function Client:join_server(address, port, name)
	address = address or self.address
	address = address or "localhost"
	port = port or self.port
	port = port or "12345"
	--notification("En train d'essayer de se connecter au serveur...")
	notification(string.format("Connection à \"%s\" (%s)...",name,address))
	print(string.format("Attempting to connect to %s (%s:%s)",name,address,tostring(port)))

	print("Configured address and port to", address, port)
	self.address = address
	self.port = port

	print("Setting peer name")
	local success, error = udp:setpeername(address, port)

	if success then
		-- If setting peer name was successful, request to join to server
		print(concat("Requesting to join ",address, ":",port, "..."))
		local msg = "join "..tostring(self.name)
		udp:send(msg)

	else
		-- If setting peer name was unsuccessful, report error
		print(concat("Error when joining ",address, ":",port," : ",error))
		self.waiting_msg = "Impossible de se connecter, vérifiez votre connection"
	end
end

function Client:get_local_ip()
	-- This attempts to get the network IP. 
	--You can create a UDP socket, use setpeername to bind it to any 
	--address outside your network, then use getsockname to get the 
	--local IP. This should work even if the remote address doesn't 
	--actually exist, as long as it gets routed outside your network 
	--(so you can use a reserved address, like something in the 
	--240.0.0.1 - 255.255.255.254 range).
--[[
	udp:setpeername("*")
	local ip = udp:getsockname()
	print("YOOOO THIS IS MY IP RIGHT????",ip)
--]]

--[[
	local hostname = socket.dns.gethostname()
	local address = socket.dns.toip(hostname)
	print("Local address", address)
	return address
--]]

	-- This attempts to get the network IP by running 'ipconfig'/'ip a'/MACOS
	-- and extracting the first instance using a Lua pattern... which is 
	-- super dumb and stupid. 
	-- But hopefully it just works and fuck it if doesn't ¯\_(ツ)_/¯

	local platform = love.system.getOS()

	-- The command to get the IP is OS-dependent
	if platform == "Windows" then
		local handle = io.popen("ipconfig")
		local output = handle:read("*a")

		local pat = ".*(192%.168%.[%d]+%.[%d]+).*"
		local ip = output:match(pat)
		
		handle:close()
		return ip

	elseif platform == "OS X" then
		--TODO: get_local_ip for OS X

	elseif platform == "Linux" then
		local handle = io.popen("ip a")
		local output = handle:read("*a")

		local pat = ".*(192%.168%.[%d]+%.[%d]+)/.*"
		local ip = output:match(pat)
		
		handle:close()
		return ip
	end
end

function Client:attempt_next_connection()
	self.fallback_number = self.fallback_number + 1
	if self.fallback_number > #self.fallback_servers then 
		--print("Maximum fallback server number reached, aborting connection attempt")
		--self.do_timeout = false
		return 
	end

	local server = self.fallback_servers[self.fallback_number]
	local ip, name = server.ip, server.name
	if not name then   name = ip  end

	if ip then
		self:join_server(ip, "12345", name) 
	else
		self:join_server("localhost", "12345", name)
	end
end

function Client:send(msg)	
	if self.is_connected then
		udp:send(msg)
	else

	end
end

function Client:quit()
	self:send("leave "..self.name)
end

function Client:begin_game(max_timer, seed)	
	self.game_over = false
	self.is_win = false
	
	self.max_timer = max_timer
	self.timer = max_timer
	self.board.seed = seed
	self.board:reset()

	self.is_waiting = false
	self.game_begin = true
	self.number_of_broken_tiles = 0
	print("Server began game with seed "..tostring(seed))
end

function Client:on_win()
	self.is_win = true
	self.is_waiting = true
	self.waiting_msg = "Vous avez gagné! En attente des autres joueurs..."
end

function Client:on_game_over()
	-- Check for game over/victory
	self.game_over = true
	self.is_waiting = true
	self.waiting_msg = "Perdu ! Veuillez attendre la fin de la partie."
end

function Client:draw_player_rankings(x,y)
	love.graphics.setColor(1,1,1)
	for i,player in pairs(self.rankings) do
		local dy = y + (i-1)*(32+8)

		-- If self, draw white rectangle
		local w, h = 250, 32
		if player.is_self then 
			love.graphics.rectangle("fill", x-4, dy-4, w+8, h+8)
			love.graphics.setColor(0,0,0)
		end
		-- Player name & percentage
		love.graphics.print(player.name, x+40, dy)
		print_justify_right(concat(player.percentage,"%"), x+w, dy)
		-- Rank
		love.graphics.setColor(1,1,1)
		draw_rank_medal(player.rank, {.4,.4,.4}, x, dy)
	end
end

function Client:get_name()
	local opsys = love.system.getOS( )

	local name = "Hello_:D"..tostring(love.math.random(0,999))
	if opsys == "Windows" then
		name = os.getenv("USERNAME") 
	else
		name = os.getenv("USER")
	end

	-- Remove the separator character ("&") defined in constants.lua
	name = name:gsub(LISTRANKS_SEP,"_")
	return name
end

function Client:request_for_rankings()
	-- Request the server for other player's rankings
	local dt = love.timer.getDelta()
	self.ranking_request_timer = self.ranking_request_timer - dt

	if self.ranking_request_timer < 0 then
		self:queue_request("listranks","plslol")
		self.ranking_request_timer = self.ranking_request_timer + self.max_ranking_request_timer
	end
end

function Client:get_random_player()
	if #self.rankings > 1 then
		local randply 
		for i=1,10 do
			local randply = self.rankings[love.math.random(1, #self.rankings)]
			if randply.name ~= self.name then
				return randply.name
			end
		end
	end
	return nil
end

function Client:on_new_chat_msg(msg)
	self:queue_request("chat", msg)
end

return Client