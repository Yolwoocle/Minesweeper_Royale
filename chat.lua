local Class = require "class"
local utf8 = require 'lua-utf8'
require "constants"
require 'util'

uft8 = {}
setmetatable(uft8, {__index=function() error("it's utf8 not uft8 you dumbass") end})

local Chat = Class:inherit()

-- TODO: InputField class

function Chat:init(parent)
	self.parent = parent -- Client or Server
	self.chat = {}
	self.display_chat = false
	self.block_next_input = false
	self.max_msg = 20  --MAximum nb of msgs that the chat can store
	
	self.input = ""
	self.cursor_pos = 0
end

function Chat:update(dt)
	-- Update chat
	for i,msg in pairs(self.chat) do
		msg.t = msg.t - dt
	end
	if #self.chat > self.max_msg then
		for i=self.max_msg, #self.chat-1 do
			table.remove(self.chat, 1)
		end
	end

	print("héy", utf8.sub("héy",1,2))
end

function Chat:draw()
	-- Draw chat messages
	for i = 1, #self.chat do
		local msg = self.chat[i]
		-- Transparecy
		local a
		if self.display_chat then
			a = 1
		else
			a = math.min(1, msg.t)
		end

		local y = WINDOW_HEIGHT - (#self.chat+2)*32 + i*32
		if self.display_chat then   
			-- Background rectangle if on input mode
			love.graphics.setColor(0,0,0, 0.5)
			love.graphics.rectangle("fill", 0,y, get_text_width(msg.msg)+8, 32)
		end
		-- Draw text 
		love.graphics.setColor(1,1,1, a)
		if msg.color then   
			-- Custom colors
			local col = msg.color
			col[4] = a
			love.graphics.setColor(col)
		end
		love.graphics.print(tostring(msg.msg), 2, y)
		love.graphics.setColor(1,1,1)
		
		if self.display_chat then
			-- Input field: black rectangle
			local y =WINDOW_HEIGHT - 32
			love.graphics.setColor(0,0,0,0.8)
			love.graphics.rectangle("fill", 0,y, WINDOW_WIDTH, 32)
			love.graphics.setColor(1,1,1)
			love.graphics.print(self.input, 2, y)

			-- Blinking cursor
			local t = 1
			if love.timer.getTime() % t < t/2 then
				local substr = utf8.sub(self.input, 1, self.cursor_pos)
				local x = get_text_width(substr)
				love.graphics.setColor(1,1,1)
				love.graphics.rectangle("fill", x,y, 2,32)
			end 
		end
	end
end

function Chat:new_msg(...)
	local msg = concat(...)
	local msg, color = self:parse_color(msg)
	local entry = {
		color = color,
		msg = msg, 
		t = 10,
	}
	table.insert(self.chat, entry)
	
	-- Delete later messages
	if #self.chat > 20 then
		table.remove(self.chat, 1)
	end
end

function Chat:keypressed(key)
	-- Toggle input mode
	if key == 't' and not self.display_chat then
		self.display_chat = true
		self.block_next_input = true
	end
	if key == 'escape' and self.display_chat then
		self.display_chat = false
	end

	-- Send messages
	if key == "return" and self.display_chat then
		self:send_input()
	end

	-- Beckspace deletes text
	if key == 'backspace' then
		self:backspace_input(1)
	end

	-- Move cursor
	if key == 'left' then
		self:move_cursor(-1)
	end
	if key == 'right' then
		self:move_cursor(1)
	end
end

function Chat:textinput(text)
	if self.block_next_input then
		self.block_next_input = false
		return
	end

	text = sanitize_input(text)

	if self.display_chat then
		local a = utf8.sub(self.input, 1, self.cursor_pos)
		local b = utf8.sub(self.input, self.cursor_pos+1, utf8.len(self.input))
		self.input = a..text..b
		self.cursor_pos = self.cursor_pos + utf8.len(text)
	end
end

function Chat:backspace_input(n)
	if #self.input == 0 then
		return 
	end

	local first = utf8.sub(self.input, 1, self.cursor_pos-n)
	local last  = utf8.sub(self.input, self.cursor_pos+1, -1) 
	self.input = first..last
	self.cursor_pos = clamp(self.cursor_pos - n, 0, utf8.len(self.input))
end

function Chat:send_input()
	if utf8.sub(self.input, 1,1) == "/" then
		-- Submit commands
		local text = utf8.sub(self.input, 2,-1)
		self:send_command(split_str(text, " "))
	else
		-- Submit chat message
		local username = self.parent.name
		local msg = concat("<",username,"> ",self.input)
		self:new_msg(msg)
	end
	self.input = ''
	self.display_chat = false
	self.cursor_pos = 0

	self.parent:on_new_chat_msg(msg)
end

function Chat:send_command(a)
	local cmd = a[1]
	table.remove(a, 1)
	local parms = a

	if self.parent.type == "client" then
		if cmd == "connect" then
			local ip = parms[1]
			if not ip then   
				self:new_msg("%rErreur: aucune addresse fournie (format: client <ip> [port] [nom])")
				return 
			end
			local port = parms[2] or 12345
			local nom = parms[3] or tostring(ip)
			self.parent:join_server(ip, port, nom)
		end

	elseif self.parent.type == "server" then
		if cmd == "kick" then
			local user = 
			self.parent:kick_user()
		end

	end
end

function Chat:clear()
	self.chat = {}
end


function Chat:move_cursor(delta)
	self.cursor_pos = clamp(self.cursor_pos + delta, 0, #self.input)
end

function Chat:parse_color(msg)
	local col = COL_WHITE
	if utf8.sub(msg,1,1)=="%" then
		local code = utf8.sub(msg,2,2)
		msg = utf8.sub(msg,3,-1)
		
		if code == "y" then 
			col = COL_YELLOW 
		elseif code == "r" then
			col = COL_RED
		end

	end
	return msg, col
end

return Chat