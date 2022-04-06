local function new_source(path, type, args)
	local source = love.audio.newSource(path, type)
	if not args then  return source  end
	
	if args.looping then
		source:setLooping(true)
	end
	return source
end

local sfx = {}
sfx.generate = new_source("sfx/generate.wav", "static")

-- [[
sfx.break_1 = new_source("sfx/click1.ogg", "static")
sfx.break_2 = new_source("sfx/click2.ogg", "static")
sfx.break_3 = new_source("sfx/click3.ogg", "static")
sfx.break_4 = new_source("sfx/click4.ogg", "static")
sfx.break_5 = new_source("sfx/click5.ogg", "static")
--]]

return sfx