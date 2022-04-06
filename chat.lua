local Class = require "class"
local utf8 = require "utf8"
require "constants"

local Chat = Class:inherit()

-- TODO: InputField class

function Chat:init(parent)
	self.parent = parent
	self.chat = {}
	self.display_chat = false
	self.input = ""
	self.block_next_input = false
	self.max_msg = 20
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

	-- Accept text input
	if self.display_chat then 
		self:accept_text_input()
	end
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
				local x = get_text_width(self.input)
				love.graphics.setColor(1,1,1)
				love.graphics.rectangle("fill", x,y, 16,32)
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
end

function Chat:accept_text_input()
	--self.input
end

function Chat:textinput(text)
	if self.block_next_input then
		self.block_next_input = false
		return
	end

	if self.display_chat then
		self.input = self.input .. text
	end
end

function Chat:send_input()
	local username = self.parent.name
	local msg = concat("<",username,"> ",self.input)
	self:new_msg(msg)
	self.input = ''
	self.display_chat = false

	self.parent:on_new_chat_msg(msg)
end

function Chat:clear()
	self.chat = {}
end

function Chat:backspace_input(n)
	if #self.input == 0 then
		return 
	end

	--self.input = string.sub(self.input, 0, math.max(0, #self.input - n))
	local b = math.min(0, -n)
	local b = utf8.offset(self.input, b) - 1
	self.input = string.sub(self.input, 0, b)
end

function Chat:parse_color(msg)
	local col = COL_WHITE
	if string.sub(msg,1,1)=="%" then
		local code = string.sub(msg,2,2)
		
		if code == "y" then 
			msg = string.sub(msg,3,-1)
			col = COL_YELLOW 
		end

	end
	return msg, col
end

return Chat