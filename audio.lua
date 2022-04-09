local Class = require 'class'

local AudioManager = Class:inherit()

function AudioManager:init()
	
end

function AudioManager:play(snd, pitchvar_min, pitchvar_max)
	pitchvar_min = pitchvar_min or 1
	if not pitchvar_max then   pitchvar_max = -(pitchvar_min - 1) + 1   end

	if DO_SFX then
		local source = snd:clone()
		local pitch = random_range(pitchvar_min, pitchvar_max)
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