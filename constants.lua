require 'util'

-- Messages
MSG_PLEASE_WAIT_SERVER = "Veuillez attendre le serveur \\('o')/"
MSG_CONNECTION_ESTABLISHED_WITH_SERVER = "Connection établie avec le serveur :D"

MSG_LOCAL_NETWORK = "Réseau local"

DEFAULT_SERVERIP_TXT = [[# Server IPs go here. Format: "<serverip> [name] [port]"
# Add '#' at the beginning of a line to make a comment.]]

LISTRANKS_SEP = "&" --Separtor used for the `listranks` command

COL_BLACK = rgb(0,0,0)
COL_GRAY = rgb(128,128,128)
COL_GREY = COL_GRAY --<o/ dab on the haters
COL_WHITE = rgb(255,255,255)
COL_GREEN = rgb(44,200,44)
COL_BLUE = rgb(45,45,210)
COL_RED = rgb(255,0,33)
COL_YELLOW = rgb(255,255,0)
COL_REVEALED = rgb(25,25,25)
COL_HIDDEN = rgb(100, 200, 77)

PALETTE_NUMBERS = {
	[0] = COL_BLACK,
	[1] = COL_BLUE,
	[2] = COL_GREEN,
	[3] = COL_RED,
	[4] = rgb(200,255,50),
	[5] = rgb(200,0,255),
	[6] = rgb(0,188,211),
	[7] = rgb(127,127,127),
	[8] = rgb(255,66,234),	
}