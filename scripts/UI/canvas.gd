extends CanvasLayer

@onready var main_menu = $MainMenu
@onready var hud = $HUD
@onready var fader = $ColorRect

func _ready():
	main_menu.show()
