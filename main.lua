local Class = require "class"
local Game = require "game"
local Board = require "board"
local NetworkManager = require "network"

-- Global parameters
WINDOW_WIDTH = 400
WINDOW_HEIGHT = 300

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

local is_server = false
local is_fullscreen = false

local notifs = {}
local game 

function love.load(arg)
	if arg and arg[1] == "-server" then
		is_server = true
	end
	love.window.setMode(0, 0, {fullscreen = true, vsync = true})
	SCREEN_WIDTH = love.graphics.getWidth()
	SCREEN_HEIGHT = love.graphics.getHeight()

	if is_server then
		love.window.setTitle("Minesweeper Royale - Server")
		is_fullscreen = true
		love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
			fullscreen = false,
			resizable = true
		})
	else
		love.window.setTitle("Minesweeper Royale")
		is_fullscreen = false
		love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT, {
			fullscreen = false, 
			resizable = true,
		})
	end
	game = Game:new(is_server)

	-- Load fonts
	local font_regular = love.graphics.newFont("fonts/Poppins-Regular.ttf", 24)
	love.graphics.setFont(font_regular)
end

function love.update(dt)
	game:update(dt)

	for i,notif in pairs(notifs) do
		notif.t = notif.t - dt
		if notif.t < 0 then
			table.remove(notifs, 1)
		end
	end

	if #notifs > 15 then
		for i=1, #notifs-15 do
			table.remove(notifs, 1)
		end
	end
end

function love.draw()
	game:draw()

	for i,notif in pairs(notifs) do
		love.graphics.setColor(1,1,1, math.min(1, notif.t))
		love.graphics.print(tostring(notif.msg), 2, (i-1)*32)
		love.graphics.setColor(1,1,1)
	end
end

function love.keypressed(key)
	if key == "f5" then
		if is_server then
			if love.keyboard.isDown("lshift") then
				love.event.quit("restart")
			end
		else
			love.event.quit("restart")
		end

	elseif key == "f4" then
		if is_server then
			if love.keyboard.isDown("lshift") then
				love.event.quit()
			end
		else
			love.event.quit()
		end

	elseif key == "f11" then
		is_fullscreen = not is_fullscreen
		love.window.setFullscreen(is_fullscreen)

	elseif key == "f12" then
		-- Restart as server mode
		is_server = true
		notifs = {}
		love.load("-server")
		
	end

	if game.keypressed then  game:keypressed(key)  end
end

function love.mousepressed(x, y, button, istouch, presses)
	game:mousepressed(x, y, button)
end

function love.quit()
	game:quit()
end

function love.resize(w, h)
	WINDOW_WIDTH = w
	WINDOW_HEIGHT = h
end

function love.run()
	--  DEFAULT love.run FUNCTION: https://love2d.org/wiki/love.run 

	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end

	local dt = 0

	-- Main loop time.
	return function()
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then dt = love.timer.step() end

		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled

		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())

			if love.draw then love.draw() end

			love.graphics.present()
		end

		if love.timer then love.timer.sleep(0.001) end
	end
end


function notification(...)
	local msg = concat(...)
	table.insert(notifs, {msg=msg, t=10})
	if #notifs > 20 then
		table.remove(notifs, 1)
	end
end