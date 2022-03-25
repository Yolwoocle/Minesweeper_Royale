local socket = require "socket"
local Class = require "class"
local Board = require "board"
local font = require "font"

local Client = Class:inherit()
function Client:init()
	self.is_waiting = false
	self.is_win = false
	self.board = Board:new()
	self.name = self:get_name()

	-- Networking
	self:init_socket()
end

function Client:init_socket()
	print("Client started")
	self.address = self:read_serverip("localhost")
	self.port = 12345

	-- How long to wait, in seconds, before requesting an update
	self.updaterate = 0.1 

	self.udp = socket.udp()
	self.udp:settimeout(0)
	self.udp:setpeername(self.address, self.port)
	self.msg = ""

	local dg = "join "..tostring(self.name)
	self.udp:send(dg)
	
	self.t = 0 
end

function Client:update(dt)
	self.board:update(dt)
	if self.board:is_winning() then
		self.is_win = true
	end

	self:update_socket(dt)
end

function Client:draw()
	self.board:draw()
	if self.board.game_over then
		self:draw_game_over()
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
	if self.board.on_button1 then  self.board:on_button1(tx, ty, is_valid)  end

	-- Prepare network package for later
	self.state = "break"
	self.state_args = concat(tx," ",ty," ",bool_to_int(is_valid))
end

function Client:on_button2(tx, ty, is_valid)
	if self.board.on_button2 then  self.board:on_button2(tx, ty, is_valid)  end

	self.state = "flag"
	self.state_args = concat(tx," ",ty," ",bool_to_int(is_valid))
end

function Client:update_socket(dt)
	self.t = self.t + dt 
	if self.t > self.updaterate then
		local msg 
		if self.state ~= "" then
			-- If breaking a tile
			if self.state == "break" then
				msg = "break "..self.state_args
				
			elseif self.state == "flag" then
				msg = "flag "..self.state_args
			
			end
			self.state = ""	
		end
	
		-- Send the packet
		if msg then
			self.udp:send(msg)	
		end
		
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
			local cmd, parms = data:match("^(%S*) (.*)$")
			print("Received server data:", data)

			if cmd == 'assignid' then
				self.id = tonumber(parms)

			elseif cmd == "assignseed" then
				local seed = parms:match("^(%-?[%d.e]*)$")
				seed = tonumber(seed)
				self.board.seed = seed

			else
				print("Unrecognised server command:", cmd)
			end
		
		-- If data was nil, msg will contain a description of the problem.
		elseif msg ~= 'timeout' then 
			notification("Network error: "..tostring(msg))
		end
	until not data 
end

function Client:read_serverip(default)
	local contents, size = love.filesystem.read("serverip.txt")
	if contents then
		print(contents)
		return contents
	else
		local error = size
		notification(error)
		return default
	end
end

function Client:quit()
	self.udp:send("leave 123")
end

function Client:draw_game_over()
	--RECTANGLE rgb(120,120,233),0.4)
	love.graphics.setColor(0.3,0.3,0.5,0.7)
	local rect_width = 0.30*WINDOW_WIDTH
	local rect_height = 0.30*WINDOW_HEIGHT
	love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

	--TEXT
	love.graphics.setColor(1,1,1)
	local lose_text = "ta pairdu"
	local text_width = font.regular:getWidth(lose_text)
	local text_height = font.regular:getHeight(lose_text)
	love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	lose_text = "tu veux rejouer ?"
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
	local text = "gg!"
	draw_centered_text()
	local text_width = font.regular:getWidth(text)
	local text_height = font.regular:getHeight(text)
	love.graphics.print(text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	text = "tu veux rejouer ?"
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