local Class = require 'class'

local AudioManager = Class:inherit()

function AudioManager:init()
end

function AudioManager:play(snd)
	if DO_SFX then
		local source = snd:clone()
		source:play()
	end
end

return AudioManager