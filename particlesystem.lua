require "util"
local img = require "images"
local Class = require "class"
local Particle = require "particle"

local ParticleSystem = Class:inherit()

function ParticleSystem:init()
	self.particles = {}
end

function ParticleSystem:new_particle(...)
	table.insert(self.particles, Particle:new(...))
end

function ParticleSystem:update(dt)
	for i,ptc in pairs(self.particles) do
		ptc:update(dt)
		if ptc.life < 0 or ptc.s < 0.1 then  
			table.remove(self.particles, i)
		end
	end
end

function ParticleSystem:draw()
	for i,ptc in pairs(self.particles) do
		ptc:draw()
	end
end

return ParticleSystem