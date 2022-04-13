import math
import os
import time
import re
import random

class Vect:
	def __init__(self, x, y) -> None:
		self.x = x
		self.y = y

############
### TILE ###
############

class Tile:
	def __init__(self) -> None:
		self.val = 0
		self.is_hidden = True
		self.is_bomb = False
	
	def __str__(self) -> str:
		if self.is_hidden:
			return "[]"
		if self.is_bomb:
			return "# "
		if self.val == 0:
			return ". "
		return str(self.val)+" "

	def reveal(self):
		self.is_hidden = False


#############
### BOARD ###
#############

class Board:
	def __init__(self, w, h, n) -> None:
		self.width = w
		self.height = h
		self.number_of_bombs = n
		self.grid = [[Tile() for i in range(w)] for j in range(h)]
	
	def reset(self):
		self.grid = [[Tile() for i in range(self.width)] for j in range(self.height)]

	def set_tile(self, x, y, val):
		# Assigne une valeur à une case (x,y) de la grille
		assert self.is_valid(x,y), "Invalid coordinates"
		self.grid[y][x] = val

	def get_tile(self, x, y):
		# Renvoie la valeur de la case (x,y) de la grille
		assert self.is_valid(x,y), "Invalid coordinates" 
		return self.grid[y][x]
	
	def reveal_tile(self, x, y):
		# Dévoile la case à (x,y)
		assert self.is_valid(x,y), "Invalid coordinates" 
		return self.grid[y][x].reveal()
		
	def is_valid(self, x, y):
		return (0 <= x < self.width and 0 <= y < self.height)

	def generate(self, startx, starty):
		self.reset()
		maximum = self.width * self.height - 9
		coords = set()
		while len(coords) < min(self.number_of_bombs, maximum):
			rx, ry = random.randint(0, self.width-1), random.randint(0, self.height-1)
			# Si c'est pas dans la zone de départ
			if not(startx-1 <= rx <= startx+1 and starty-1 <= ry <= starty+1):
				coords.add(Vect(rx,ry))

		for c in coords:
			self.get_tile(c.x, c.y).is_bomb = True
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					bomb_x = c.x+dx
					bomb_y = c.y+dy
					if self.is_valid(bomb_x, bomb_y):
						self.get_tile(bomb_x, bomb_y).val += 1

	def recursive_reveal_board(self, x, y):
		self.grid[y][x].reveal()
	
		# Révéler les cases autour
		for ox in [-1, 0, 1]:
			for oy in [-1, 0, 1]:
				# Si la case est valide...
				if self.is_valid(x+ox, y+oy):
					tile = self.grid[y+oy][x+ox]
					is_hidden = tile.is_hidden

					tile.reveal()
					if is_hidden and tile.val == 0:
						self.recursive_reveal_board(x+ox, y+oy)
	
	def number_of_hidden_tiles(self):
		n = 0
		for line in self.grid:
			for tile in line:
				if tile.is_hidden:
					n += 1
		return n

	def display(self):
		caption = "   "
		for i in range(self.width):
			msg = str(i)+" "*10
			caption += msg[:2]
		print(caption)
		print("--+" + "--"*self.width)

		# Affiche la grille à l'écran
		for i in range(len(self.grid)):
			print( end = (str(i)+" "*10)[:2] + "|")
			
			line = self.grid[i]
			for tile in line:
				print(tile, end="")
			print()

	def reveal_all_bombs(self):
		for x in range(self.width):
			for y in range(self.height):
				tile = self.get_tile(x,y)
				if tile.is_bomb:
					tile.reveal()

############
### GAME ###
############

class Game:
	def __init__(self) -> None:
		self.board = Board(15, 8, 12)
		self.running = True
		self.start_time = 0
		self.new_game()
		
	def new_game(self):
		self.board.reset()
		self.start_time = time.time()

	def main(self):
		print()
		print("****************************************")
		print("*** ヾ(⌐■_■)ノ♪ Démineur ヾ(⌐■_■)ノ♪ ***")
		print("****************************************")
		print()
		while self.running:
			self.board.display()
			print(f"Nombre de bombes: {self.board.number_of_bombs}")
			print("\"q\": quitter")
			print("Coordonnées x y, séparées par un espace: ")
			prompt = input("> ")

			if re.match(r"\d+ \d+", prompt):
				self.place_tile(prompt)
			elif prompt == "q":
				# Quitter la partie
				self.running = False
			else:
				# Entrée invalide
				print("Entrée invalide. Réessayez.")
			
			# Condition de victoire
			if self.board.number_of_hidden_tiles() == self.board.number_of_bombs:
				self.board.display()
				
				done = time.time()
				elapsed = math.floor(done - self.start_time)
				print(f"Félicitations! Vous avez gagné. Votre temps: {elapsed} sec")
				input("Appuyez sur entrée pour rejouer")
				self.new_game()
				print("*** Nouvelle partie ***")
			
			print("*" * self.board.width * 2)
		print("Merci d'avoir joué!")
	

	def place_tile(self, prompt):
		x, y = map(int, prompt.split(" "))
		# On vérifie que l'entrée est valide
		if not self.board.is_valid(x,y):
			return
		
		# Si la case est 0, révéler récursivement le plateau
		if self.board.get_tile(x,y).val == 0:
			self.board.generate(x,y)
			self.board.recursive_reveal_board(x,y)

		# Si la case n'est pas 0
		else:
			self.board.reveal_tile(x,y)
			if self.board.get_tile(x,y).is_bomb:
				# Si c'est une bombe, perdre 
				self.board.reveal_all_bombs()
				self.board.display()
				response = input("Perdu! Rejouer? (O/n)")
				if response == "n":
					# Quitter le jeu
					self.running = False
				
				else:
					# Rejouer
					self.new_game()
					print("*** Nouvelle partie ***")

game = Game()
if __name__ == "__main__":
	game.main()