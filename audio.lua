local Class = require 'class'

local AudioManager = Class:inherit()

function AudioManager:init()
	
end

function AudioManager:play(snd, pitchvar)
	pitchvar = pitchvar or 0

	if DO_SFX then
		local source = snd:clone()
		local pitch = 1 + random_neighbor(pitchvar)
		source:setPitch(pitch)
		source:play()
	end
end

function AudioManager:play_random(snd, ...)
	local snd = snd[love.math.random(1, #snd)]
	if DO_SFX then
		self:play(snd, ...)
		local source = snd:clone()
		source:play()
	end
end

return AudioManager