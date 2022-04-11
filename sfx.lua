local function new_source(path, type, args)
	type = type or "static"

	local source = love.audio.newSource(path, type)
	if not args then  return source  end
	
	if args.looping then
		source:setLooping(true)
	end
	return source
end

local sfx = {}
sfx.generate = new_source("sfx/generate.wav", "static")

sfx.table_break = {
	[1] = new_source("sfx/break_1.wav", "static"),
	[2] = new_source("sfx/break_2.wav", "static"),
	[3] = new_source("sfx/break_3.wav", "static"),
	[4] = new_source("sfx/break_4.wav", "static"),
	[5] = new_source("sfx/break_4.wav", "static"),
	[6] = new_source("sfx/break_4.wav", "static"),
	[7] = new_source("sfx/break_4.wav", "static"),
	[8] = new_source("sfx/break_4.wav", "static"),
}

sfx.flag_remove = new_source("sfx/flag_remove.wav", "static")
sfx.flag_place = new_source("sfx/flag_place.wav", "static")

sfx.explode = new_source("sfx/explode.wav")
sfx.click = {
	new_source("sfx/click1.ogg"),
	new_source("sfx/click2.ogg"),
	new_source("sfx/click3.ogg"),
	new_source("sfx/click4.ogg"),
	new_source("sfx/click5.ogg"),
}

sfx.numbers = {
	[0] = new_source("sfx/go.ogg"),
	[1] = new_source("sfx/1.ogg"),
	[2] = new_source("sfx/2.ogg"),
	[3] = new_source("sfx/3.ogg"),
	[4] = new_source("sfx/4.ogg"),
	[5] = new_source("sfx/5.ogg"),
	[6] = new_source("sfx/6.ogg"),
	[7] = new_source("sfx/7.ogg"),
	[8] = new_source("sfx/8.ogg"),
	[9] = new_source("sfx/9.ogg"),
	[10] = new_source("sfx/10.ogg"),
}

sfx.tick = new_source("sfx/tick.flac")

return sfx
--[[
sfx.break_1 = new_source("sfx/click1.ogg", "static")
sfx.break_2 = new_source("sfx/click2.ogg", "static")
sfx.break_3 = new_source("sfx/click3.ogg", "static")
sfx.break_4 = new_source("sfx/click4.ogg", "static")
sfx.break_5 = new_source("sfx/click5.ogg", "static")

sfx.flag_place_list = {
	--new_source("sfx/flag_place1.ogg", "static"),
	--new_source("sfx/flag_place2.ogg", "static"),
	new_source("sfx/flag_place3.ogg", "static"),
	new_source("sfx/flag_place4.ogg", "static"),
	new_source("sfx/flag_place5.ogg", "static"),
	new_source("sfx/flag_place6.ogg", "static"),
	--new_source("sfx/flag_place7.ogg", "static"),
	--new_source("sfx/flag_place8.ogg", "static"),
}
sfx.bomb_explode_list = {
	new_source("sfx/bomb_explode_001.ogg", 'static'),
	new_source("sfx/bomb_explode_002.ogg", 'static'),
	new_source("sfx/bomb_explode_003.ogg", 'static'),
}
sfx.break_list = {
	sfx.break_1, 
	sfx.break_2, 
	sfx.break_3
}
--]]
