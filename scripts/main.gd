extends Node2D

@onready var ani: AnimationPlayer = $UI/AnimationPlayer
@onready var rect: ColorRect = $UI/ColorRect
@onready var spawner: Node = $Spawner

var game_over_sfx = preload("res://audio/sfx/game_over.mp3")

var interactive_stream = preload("res://audio/music/music.tres")

func _ready() -> void:
	ani.play("blend_in")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioManager.play_music(interactive_stream)

func _on_main_menu_game_start() -> void:
	ani.play("game_start")
	AudioManager.switch_music_state("Main")

func game_start_ani_finished() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	spawner.init()
	$foreground/tower/player.off = false

func reload_init() -> void:
	ani.play("blend_out")

func reload() -> void:
	get_tree().reload_current_scene()

func _on_game_over_area_entered(_area: Area2D) -> void:
	ani.play("game_over",1.0,0.7)
	AudioManager.stop_music(3.0)
	AudioManager.play_sfx(game_over_sfx)
	$foreground/game_over.set_deferred("monitoring", false)
	$foreground/game_over_air.set_deferred("monitoring", false)
