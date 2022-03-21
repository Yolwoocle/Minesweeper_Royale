function love.load()
    map_w = 20
    map_h = 20
end

function love.update()

end

function love.draw()

end


function love.keypressed(key)
	if key == "f5" then
		love.event.quit("restart")
	elseif key == "escape" then
		love.event.quit()
	end
end
