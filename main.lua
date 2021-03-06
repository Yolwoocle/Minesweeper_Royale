local Class = require "class"
local Game = require "game"
local Board = require "board"
local NetworkManager = require "network"
local sfx = require "sfx"
require "constants"

-- Global parameters
WINDOW_WIDTH = 400
WINDOW_HEIGHT = 300

WINDOW_WIDTH = 800
WINDOW_HEIGHT = 600

local is_server = false
local is_fullscreen = false

game = nil 

function love.load(arg)
	DO_SFX = true
	
	-- Initialize log files for errors & stuff
	local success, message = love.filesystem.write("log.txt", "")
	if not love.filesystem.getInfo("serverip.txt") then 
		love.filesystem.write("serverip.txt", DEFAULT_SERVERIP_TXT)
	end

	-- If ran from the command line with "-server" flag, then run as server
	if arg and arg[1] == "-server" then
		is_server = true
	end

	if is_server then  	DO_SFX = false   
	else  	DO_SFX = true
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
	-- enable key repeat so backspace can be held down to trigger love.keypressed multiple times.
  love.keyboard.setKeyRepeat(true)
	
	game = Game:new(is_server)

	-- Load fonts
	local font_regular = love.graphics.newFont("fonts/Poppins-Regular.ttf", 24)
	love.graphics.setFont(font_regular)
end

function love.update(dt)
	game:update(dt)
end

function love.draw()
	game:draw()
end

function love.keypressed(key)
	if key == "f2" then
		local filename = os.date('demineur_royale_%Y-%m-%d_%H-%M-%S.png') 
		love.graphics.captureScreenshot(filename)
		notification("Capture d'écran capturée. Faites '/folder' pour dévoiler le dossier.")

	elseif key == "f5" then
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

	elseif key == "f12" and love.keyboard.isDown("lshift") then
		if not is_server then
			-- Restart as server mode
			is_server = true
			chat:clear()
			love.load("-server")
		end
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
	if game.resize then   game:resize(w,h)   end
end

function love.textinput(text)
	game:textinput(text)
end

oldprint = print
function print(...)
	oldprint(...)
	local success, errormsg = love.filesystem.append("log.txt", concat(...).."\n")
end