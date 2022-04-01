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

function ParticleSystem:new_thrown_particle(img,x,y,s)
	-- A "thrown" particle is something like the squares when a tile is mined,
	-- or when a flag is removed 
	local s = s or 1
	local dx = random_neighbor(2)
	local dy = random_range(0,-3)
	local dr = random_neighbor(0.05)
	local ds = random_range(0.01, 0.02)
	local g = 0.1
	local fx = 0.8
	self:new_particle(img, x, y, 0, s, dx, dy, dr, ds, g, fx) 
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