local Class = require "class"

local Chat = Class:inherit()
function Chat:init(parent)
	self.parent = parent
	self.chat = {}
	self.display_chat = false
	self.input = ""
	self.block_next_input = false
end

function Chat:update(dt)
	-- Update chat
	for i,msg in pairs(self.chat) do
		msg.t = msg.t - dt
	end
	if #self.chat > 20 then
		for i=1, #self.chat-20 do
			table.remove(self.chat, 1)
		end
	end

	-- Accept text input
	if self.display_chat then 
		self:accept_text_input()
	end
end

function Chat:draw()
	for i = 1, #self.chat do
		local msg = self.chat[i]
		-- Transparecy
		local a
		if self.display_chat then
			a = 1
		else
			a = math.min(1, msg.t)
		end

		local y = WINDOW_HEIGHT - (i+1)*32
		if self.display_chat then   
			-- Background rectangle
			love.graphics.setColor(0,0,0, 0.5)
			love.graphics.rectangle("fill", 0,y, get_text_width(msg.msg)+8, 32)
		end
		-- Draw text 
		love.graphics.setColor(1,1,1, a)
		love.graphics.print(tostring(msg.msg), 2, y)
		love.graphics.setColor(1,1,1)
		
		if self.display_chat then
			-- Input
			love.graphics.setColor(0,0,0,0.8)
			love.graphics.rectangle("fill", 0,WINDOW_HEIGHT-32, WINDOW_WIDTH, 32)
			love.graphics.setColor(1,1,1)
			love.graphics.print(self.input, 2, WINDOW_HEIGHT - 32)
		end
	end
end

function Chat:new_msg(...)
	local msg = concat(...)
	table.insert(self.chat, 1, {msg=msg, t=10})
	
	-- Delete later messages
	if #self.chat > 20 then
		table.remove(self.chat, 1)
	end
end

function Chat:keypressed(key)
	-- Toggle input mode
	if not self.display_chat and key == 't' then
		self.display_chat = true
		self.block_next_input = true
	end
	if self.display_chat and key == 'escape' then
		self.display_chat = false
	end

	-- Send messages
	if self.display_chat and key == "return" then
		self:send_input()
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
	self:new_msg("<",username,"> ",self.input)
	self.input = ''
	self.display_chat = false
end

return Chat