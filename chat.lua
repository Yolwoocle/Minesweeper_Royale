local Class = require "class"
local utf8 = require 'utf8'
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
	self.max_msg = 20  --Maximum nb of msgs that the chat can store
	
	self.input = ""
	self.cursor_pos = 0

	self.show_command_list = false

	self.commands = {
		["connect"] = self:new_cmd("client", function(self, parms)
			self.parent:cmd_connect(parms)
		end),
		
		["ping"] = self:new_cmd("client", function(self, parms)
			self.parent:cmd_ping(parms)
		end),
		
		["name"] = self:new_cmd("client", function(self, parms)
			self.parent:cmd_name(parms)
		end),
		
		["folder"] = self:new_cmd("all", function(self, parms)
			-- Copies to the clipboard the path to the screeshots folder 
			local filepath = love.filesystem.getSaveDirectory()
			love.system.setClipboardText(filepath)
			notification("Chemin du dossier des captures d'écran copié.")
			return
		end),

		-- Server commands
		["kick"] = self:new_cmd("server", function(self, parms)
			local username = parms[1]
			if not username or utf8.len(username) == 0 then  
				notification("%rFormat: /kick <nom d'utilisateur>")
			end
			self.parent:kick_user(username)
		end),

		["stopgame"] = self:new_cmd("server", function(self, parms)
			self.parent:send_chat_message("%yLe serveur a stoppé la partie.")
			self.parent:stop_game()
		end),

		["help"] = self:new_cmd("client", function(self, parms)
			self.parent.show_help = not self.parent.show_help	
		end),
  
		["color"] = self:new_cmd("client", function(self, parms)
			self.parent:cmd_color(parms)
		end),

		["clear"] = self:new_cmd("client", function(self, parms)
			self.chat = {}
		end),
		
		["stop"] = self:new_cmd("server", function(self, parms) 
			self.parent:stop()
		end),

		-- Templates
		["___"] = self:new_cmd("____", function(self, parms) 
		end),
	}
end

function Chat:update(dt)
	-- Update chat
	for i,msg in pairs(self.chat) do
		msg.t = msg.t - dt
	end
	-- Remove old messages
	if #self.chat > self.max_msg then
		for i=self.max_msg, #self.chat-1 do
			table.remove(self.chat, 1)
		end
	end

	-- Command list
	self.show_command_list = (utf8.sub(self.input,1,1) == "/")
end

function Chat:draw()
	local y = WINDOW_HEIGHT - 32
	
	-- Draw chat messages
	for i = #self.chat, 1, -1 do
		-- Draw message
		local msg = self.chat[i]
		y = self:draw_msg(msg, 2, y)

		if self.display_chat then
			-- Input field: black rectangle
			local y = WINDOW_HEIGHT - 32
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

	-- Show command list
	local text_h = get_text_height(" ")
	love.graphics.setColor(COL_WHITE)
	if self.show_command_list then
		-- Generate table of commands to display
		local commands = {}
		local text_w = 0
		for name,cmd in pairs(self.commands) do
			local text = "/"..name
			local w = get_text_width(text) + 8
			local input_len = utf8.len(self.input)

			-- If the beginning of input matches OR input is just a slash
			local input_matches = (utf8.sub(text,1,input_len) == self.input) or (input_len == 1)
			local type_matches = (cmd.type == self.parent.type) or (cmd.type == "all")
			if type_matches and input_matches then
				table.insert(commands, text)
				-- Define the maximum length text
				if w > text_w then   text_w = w    end
			end
		end
		
		-- Display list of all commands
		local i = 2
		for _,name in pairs(commands) do
			local y = WINDOW_HEIGHT - i*text_h
			local text = name
			love.graphics.setColor(0,0,0,.8)
			love.graphics.rectangle("fill", 2, y, text_w, text_h)
			love.graphics.setColor(COL_WHITE)
			love.graphics.print(text, 2, y)
			i=i+1
		end
	end
end

function Chat:draw_msg(msg,x,y)
	-- Transparency
	local a
	if self.display_chat then
		a = 1
	else
		a = math.min(1, msg.t)
	end

	-- Draw text 
	local width, wrappedtext = love.graphics.getFont():getWrap(msg.msg, WINDOW_WIDTH)
	local height = #wrappedtext * 32
	local y = y - 32 * #wrappedtext

	-- Background rectangle if on input mode
	if self.display_chat then   
		love.graphics.setColor(0,0,0, 0.5)
		love.graphics.rectangle("fill", 0,y, width+8, height)
	end

	-- Custom colors
	love.graphics.setColor(1,1,1, a)
	if msg.color then   
		local col = msg.color
		col[4] = a
		love.graphics.setColor(col)
	end
	
	-- Draw lines
	local iy = y
	for i,text in pairs(wrappedtext) do
		love.graphics.print(tostring(text), x, iy)
		iy = iy + 32
	end
	love.graphics.setColor(1,1,1)
	return y
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

	-- Backspace deletes text
	if key == 'backspace' then
		self:backspace_input(1)
	end
	if key == 'delete' then
		self:del_input(1)
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
	local curtext = self.input
	if #curtext == 0 or self.cursor_pos == 0 then
		return 
	end

	local b = math.max(0, self.cursor_pos-n)
	local first = utf8.sub(curtext, 1, b)
	local last  = utf8.sub(curtext, self.cursor_pos+1, -1) 
	self.input = first..last
	self.cursor_pos = clamp(math.max(0, self.cursor_pos-n), 0, utf8.len(self.input))
end

function Chat:del_input(n)
	local len = utf8.len(self.input)

	-- When you press "del"
	local curtext = self.input
	if #curtext == 0 or self.cursor_pos == len then
		return 
	end

	local b = math.min(len+1, self.cursor_pos+1+n)
	local first = utf8.sub(curtext, 1, self.cursor_pos)
	local last  = utf8.sub(curtext, b, -1) 
	self.input = first..last
--	self.cursor_pos = clamp(math.min(len, self.cursor_pos, 0, utf8.len(self.input))
end


function Chat:send_input()
	if utf8.sub(self.input, 1,1) == "/" then
		-- Submit commands
		local text = utf8.sub(self.input, 2,-1)
		self:send_command(text)
	else
		-- Submit chat message
		local username = self.parent.name
		local msg = concat("<",username,"> ",self.input)
		self:new_msg(msg)
		self.parent:on_new_chat_msg(msg)
	end

	self.input = ''
	self.display_chat = false
	self.cursor_pos = 0
end

function Chat:send_command(text)
	local arguments = split_str(text, " ")
	local cmd = arguments[1]
	table.remove(arguments, 1)
	local parms = arguments
	parms = parms or {}

	-- Client
	local cmd = self.commands[cmd]
	if not cmd then
		self:new_msg("%rCommande inconnue:")
	end

	local is_correct_type = (self.parent.type == cmd.type) or (cmd.type == "all")
	if cmd and is_correct_type then
		cmd.func(self, parms)
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
	if utf8.sub(msg,1,1) == "%" then
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

function Chat:new_cmd(type, func)
	return {
		type = type,
		func = func,
	}
end

return Chat