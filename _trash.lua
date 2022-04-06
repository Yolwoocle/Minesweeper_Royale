function Client:draw_game_over()
	--RECTANGLE rgb(120,120,233),0.4)
	love.graphics.setColor(0.3,0.3,0.5,0.7)
	local rect_width = 0.30*WINDOW_WIDTH
	local rect_height = 0.30*WINDOW_HEIGHT
	love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

	--TEXT
	love.graphics.setColor(1,1,1)
	local lose_text = "Perdu !"
	local text_width = font.regular:getWidth(lose_text)
	local text_height = font.regular:getHeight(lose_text)
	love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	lose_text = "Rejouer ?"
	text_width = font.regular:getWidth(lose_text)
	text_height = font.regular:getHeight(lose_text)
	love.graphics.print(lose_text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2)
end

function Client:draw_winning()
	--RECTANGLE rgb(120,120,233),0.4)
	love.graphics.setColor(0.3,0.3,0.5,0.7)
	local rect_width = 0.30*WINDOW_WIDTH
	local rect_height = 0.30*WINDOW_HEIGHT
	love.graphics.rectangle("fill", rect_width, rect_height,WINDOW_WIDTH - 2*rect_width,WINDOW_HEIGHT - 2*rect_height ,0, 0, 0)

	--TEXT
	love.graphics.setColor(1,1,1)
	local text = "Félicitations !"
	draw_centered_text()
	local text_width = font.regular:getWidth(text)
	local text_height = font.regular:getHeight(text)
	love.graphics.print(text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2-40)
	
	text = "Rejouer ?"
	text_width = font.regular:getWidth(text)
	text_height = font.regular:getHeight(text)
	love.graphics.print(text,(WINDOW_WIDTH-text_width)/2,(WINDOW_HEIGHT-text_height)/2)
end