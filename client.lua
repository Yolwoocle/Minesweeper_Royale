local socket = require "socket"
local Class = require "class"
local Board = require "board"
local font = require "font"
local img = require "images"

local Client = Class:inherit()
function Client:init()
	self.game_begin = false
	self.is_waiting = true
	self.waiting_msg = "En attente du serveur..."

	self.is_win = false
	self.board = Board:new(self)
	self.name = self:get_name()
	love.window.setTitle("Minesweeper Royale - "..self.name)

	-- Networking
	self:init_socket()

	self.timer = 0

	self.rank = 0
end

function Client:init_socket()
	print("Client started")
	self.is_connected = false
	self.network_error = ""

	--Which IP in the serverip.txt file the client is connected to
	self.fallback_number = 1
	self.fallback_servers = self:read_server_ips()
	self.address = self.fallback_servers[1] or "localhost"
	self.port = 12345
	print("Set address and port "..self.address..":"..tostring(self.port))

	-- How long to wait, in seconds, before requesting an update
	self.updaterate = 0.1 

	print("Attempting connection to server")
	self.udp = socket.udp()
	self.udp:settimeout(0)
	self:join_server(self.address, self.port)
	
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
	if self.board.game_over then
		--self:draw_game_over()
	end
	
	local x, y = self.board.x, self.board.y-32
	-- Current rank
	love.graphics.setColor(.1,.1,.1)
	love.graphics.circle("fill", x+16, y-16, 16)
	love.graphics.setColor(1,1,1)
	print_centered(self.rank, x+16, y-16)
	local e = self.rank==1 and "er" or "e"
	print_centered(e, x+38, y-16, 0, .5)

	-- Clock & timer
	x = x + self.board.tile_size*3
	local time = clamp(0, math.ceil(self.timer),99999)
	love.graphics.draw(img.clock, x, y)
	love.graphics.print(time, x+32, y)

	-- Remaining flags
	x = x + self.board.tile_size*3
	local n_flags = self.board.remaining_flags
	love.graphics.draw(img.flag, x, y)
	love.graphics.print(n_flags, x+32, y)


	-- Last seconds display
	if tonumber(self.timer) <= 10 and not self.is_waiting then
		love.graphics.setFont(font.regular_huge)
		love.graphics.setColor(1,1,1,0.3)
		draw_centered_text(time, 0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
		love.graphics.setColor(1,1,1)
		love.graphics.setFont(font.regular)
	end

	-- Display waiting messages
	if self.is_waiting then
		love.graphics.setColor(0,0,0, .6)
		love.graphics.rectangle("fill",0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
		love.graphics.setColor(1,1,1)
		draw_centered_text(self.waiting_msg,0,0,WINDOW_WIDTH,WINDOW_HEIGHT)
	end

	-- Display any network errors
	if #self.network_error > 0 then
		draw_centered_text("Erreur: \""..self.network_error.."\"", 0,WINDOW_HEIGHT-32, WINDOW_WIDTH,32)
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
		self.board:on_button1(tx, ty, is_valid)  
	end

	-- Prepare network package for later
	table.insert(self.message_queue, {
		"break", concat(tx," ",ty," ",bool_to_int(is_valid)),
	})
end

function Client:on_button2(tx, ty, is_valid)
	if self.board.on_button2 and not self.is_waiting then  
		self.board:on_button2(tx, ty, is_valid)  
	end

	-- Prepare network package for later
	table.insert(self.message_queue, {
		"flag", concat(tx," ",ty," ",bool_to_int(is_valid))
	})
end

function Client:update_socket(dt)
	self.t = self.t + dt 
	if self.do_timeout then
		self.timeout_timer = self.timeout_timer + dt
	end
	if self.timeout_timer > self.timeout_max and self.fallback_number > #self.fallback_servers then
		self.timeout_timer = 0
		self.do_timeout = false
		notification("Impossible de se connecter au serveur.")
		notification("Merci de contacter l'administrateur.")
	end

	if self.t > self.updaterate then
		local msg 
		if #self.message_queue > 0 then
			local q = self.message_queue[1]
			msg = tostring(q[1]).." "..tostring(q[2])
			table.remove(self.message_queue, 1)
		end
	
		-- Send the packet
		if msg then
			self.udp:send(msg)	
		end

		-- Request for update
		local dg = "update 123"
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

		-- Receive data from server
		if data then 
			self.is_connected = true
			self.network_error = ""
			local cmd, parms = data:match("^(%S*) (.*)$")
			print("Received server data:", data)

			if cmd == 'assignid' then
				self.id = tonumber(parms)
				notification("Connection établie avec le serveur :D")

			elseif cmd == "assignseed" then
				local seed = parms:match("^(%-?[%d.e]*)$")
				seed = tonumber(seed)
				self.board.seed = seed

			elseif cmd == "update" then
				local rank = parms:match("^(%-?[%d.e]*)$")
				self.rank = rank
				seed = tonumber(seed)
				self.board.seed = seed

			elseif cmd == "begingame" then
				local maxtimer, seed = parms:match("^(%-?[%d.e]*) (%-?[%d.e]*)$")
				self.game_over = false
				self.is_win = false
				max_timer, seed = tonumber(max_timer), tonumber(seed)
				self.max_timer = maxtimer
				self.timer = maxtimer
				self.board.seed = seed
				self.board:reset()

				self.is_waiting = false
				self.game_begin = true
				print("Server began game with seed "..tostring(seed))
			
			elseif cmd == "stopgame" then
				self.game_begin = false
				self.is_waiting = true
				self.waiting_msg = "Partie terminée ! Attendez l'administrateur."
				print("Game ended. GG!")

			elseif cmd == "quit" then
				notification("Serveur stoppé ou redémarré.")
				notification("Veuillez appuyer sur 'f5' pour se reconnecter.")

			else
				print("Unrecognised server command:", cmd)
			end
		
		-- If data was nil, msg will contain a description of the problem.
		elseif msg ~= 'timeout' then 
			print(concat("ERROR: ", msg))
			self.is_connected = false
			self.network_error = msg

			if msg == "connection refused" then
				if self.address ~= "localhost" then
					print("Attempting next fallback server")
					self:attempt_next_connection()
				end
			else
				notification("Network error: "..tostring(msg))
			end

		end
	until not data 
end

function Client:read_server_ips(default)
	local ips = {}
	for line in love.filesystem.lines("serverip.txt") do
		table.insert(ips, line)
	end
	table.insert(ips, "localhost")

	return ips
end

function Client:join_server(address, port)
	address = address or self.address
	address = address or "localhost"
	port = port or self.port
	port = port or "12345"
	--notification("En train d'essayer de se connecter au serveur...")
	print("En train d'essayer de se connecter au serveur...")

	print("Configured address and port to", address, port)
	self.address = address
	self.port = port

	print("Setting peer name")
	self.udp:setpeername(address, port)
	self.msg = ""

	print(concat("Requesting to join ", address, ":",port, "..."))
	local dg = "join "..tostring(self.name)
	self.udp:send(dg)
end

function Client:attempt_next_connection()
	self.fallback_number = self.fallback_number + 1
	local ip = self.fallback_servers[self.fallback_number]
	print("Attempting to connect to ",ip)
	if ip then
		self:join_server(address, "12345")
	else
		self:join_server("localhost", "12345")
	end
end

function Client:quit()
	self.udp:send("leave "..self.name)
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

function Client:draw_game_over()
	--RECTANGLE rgb(120,120,233),0.4)
	love.graphics.setColor(0.3,0.3,0.5,0.7)
	local rect_width = 0.30*WINDOW_WIDTH
	local rect_height = 0.30*WINDOW_HEIGHT
	love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

	--TEXT
	love.graphics.setColor(1,1,1)
	local lose_text = "Perdu !"
	local text_width = font.regular:getWidth(lose_text)
	local text_height = font.regular:getHeight(lose_text)
	love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	lose_text = "Rejouer ?"
	text_width = font.regular:getWidth(lose_text)
	text_height = font.regular:getHeight(lose_text)
	love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2)
end

function Client:draw_winning()
	--RECTANGLE rgb(120,120,233),0.4)
	love.graphics.setColor(0.3,0.3,0.5,0.7)
	local rect_width = 0.30*WINDOW_WIDTH
	local rect_height = 0.30*WINDOW_HEIGHT
	love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

	--TEXT
	love.graphics.setColor(1,1,1)
	local text = "Félicitations !"
	draw_centered_text()
	local text_width = font.regular:getWidth(text)
	local text_height = font.regular:getHeight(text)
	love.graphics.print(text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	text = "Rejouer ?"
	text_width = font.regular:getWidth(text)
	text_height = font.regular:getHeight(text)
	love.graphics.print(text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2)
end

function Client:get_name()
	local opsys = love.system.getOS( )

	local name = "Hello_:D"..tostring(love.math.random(0,999))
	if opsys == "Windows" then
		name = os.getenv("USERNAME") 
	else
		name = os.getenv("USER")
	end 

	return name
end

return Client