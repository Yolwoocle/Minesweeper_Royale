require 'util'
local Class = require 'class'

local Tile = Class:inherit()
function Tile:init(val)
	self.val = val
	self.is_mine = false
	self.is_hidden = true
end

return Tile