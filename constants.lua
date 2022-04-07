require 'util'

-- Messages
MSG_PLEASE_WAIT_SERVER = "Veuillez attendre le serveur \\('o')/"
MSG_CONNECTION_ESTABLISHED_WITH_SERVER = "Connection établie avec le serveur :D"
MSG_GAME_ENDED_PLEASE_WAIT_FOR_ADMIN = "Partie terminée ! Attendez l'administrateur."
MSG_SERVER_STOPPED_OR_RESTARTED = "Serveur stoppé ou redémarré."
MSG_PRESS_F5_TO_RESTART = "Veuillez appuyer sur 'f5' pour se reconnecter."
MSG_ERROR_COLON = "Erreur:"

MSG_LOCAL_NETWORK = "Réseau local"

LISTRANKS_SEP = "&" --Separtor used for the `listranks` command

COL_BLACK = rgb(0,0,0)
COL_WHITE = rgb(255,255,255)
COL_GREEN = rgb(44,200,44)
COL_BLUE = rgb(45,45,210)
COL_RED = rgb(255,0,33)
COL_YELLOW = {1,1,0}
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