local Class = require "class"
local img = require "images"
require "util"

local Particle = Class:inherit()

-- TODO: Particle subclasses (rectangle, circle, etc)
function Particle:init(img, x, y, r, s, dx, dy, dr, ds, g, fx, fy, fr)
	self.type = "image"
	self.img = img
	self.x = x
	self.y = y
	self.r = r or 0
	self.s = s or 1
	
	self.dx = dx or 0
	self.dy = dy or 0
	self.dr = dr or 0
	self.ds = ds or 1
	self.g = g or 0

	self.fx = fx or 1
	self.fy = fy or 1
	self.fr = fr or 1
	self.fs = fs or 1

	self.life = random_range(1,2)
		
	-- Other properties
	self.col = {1,1,1}
	if type(img) == "table" then
		self.img = img[1]
		self.col = img[2]
	end

	-- Used to center the image 
	self.ox = self.img:getWidth()/2
	self.oy = self.img:getHeight()/2
end

function Particle:update(dt)
	self.life = self.life - dt
	-- Gravity
	self.dy = self.dy + self.g
	-- 
	self.dx = self.dx * (self.fx ^ dt)
	self.dy = self.dy * (self.fy ^ dt)
	self.dr = self.dr * (self.fr ^ dt)

	-- Apply displacement
	self.x = self.x + self.dx--*dt
	self.y = self.y + self.dy--*dt
	self.r = self.r + self.dr--*dt
	self.s = self.s * (self.ds ^ dt)
	--TODO: fx, fy...
end

function Particle:draw()
	--drawable, x, y, r, sx, sy, ox, oy, kx, ky
	love.graphics.setColor(self.col)
	love.graphics.draw(self.img, self.x, self.y, self.r, self.s, self.s, self.ox, self.oy)
	love.graphics.setColor(COL_WHITE)
end

return Particle