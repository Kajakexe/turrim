extends Node

const ENEMY_POOL: Dictionary = EnemyData.POOL

@export var spawn_floor_left: Node2D
@export var spawn_air_left: Node2D
@export var spawn_floor_right: Node2D
@export var spawn_air_right: Node2D

@export var starting_budget: int = 25
@export var budget_increase: int = 5

@export var recovery_budget_percent: float = 0.1
@export var recovery_timer_range: Array[float] = [2.5, 5.5]
@export var buildup_budget_percent: float = 0.5
@export var buildup_timer_range: Array[float] = [1.8, 3.0]
@export var peak_timer_range: Array[float] = [1.0, 2.0]

@export_group("Debug Settings")
@export var debug_enemy_to_spawn: String = "glider"

@onready var enemy_container: Node2D = $enemy_container
@onready var spawnpoints_floor: Array = $spawnpoints_floor.get_children()
@onready var spawnpoints_air: Array = $spawnpoints_air.get_children()
@onready var center: Node2D = $center
@onready var center_air: Node2D = $center_air

@onready var cicle_timer: Timer = $cicle
@onready var recovery_timer: Timer = $recovery
@onready var buildup_timer: Timer = $buildup
@onready var peak_timer: Timer = $peak
@onready var spawn_timer: Timer = $spawn

@onready var debug_label: Label = $debug_layer/debug_label

var current_timer_range: Array[float]
var current_phase_name: String = "None"

var budget: int = starting_budget
var current_budget: float = 0.0

var recovery_budget: float
var builtup_budget: float
var peak_budget: float

var on: bool = false

func _ready() -> void:
	if debug_label:
		debug_label.visible = OS.is_debug_build()

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F4:
			spawn_manual_enemy(debug_enemy_to_spawn)

func _process(_delta: float) -> void:
	if on and OS.is_debug_build():
		update_debug_ui()

func init() -> void:
	on = true
	
	recovery_budget = budget * recovery_budget_percent
	builtup_budget = budget * buildup_budget_percent
	peak_budget = budget * (1.0 - (recovery_budget_percent + buildup_budget_percent))
	
	if cicle_timer.is_stopped():
		cicle_timer.start()
		
	on_recovery_init()

func on_recovery_init() -> void:
	current_phase_name = "RECOVERY"
	current_budget = recovery_budget
	
	recovery_timer.start()
	current_timer_range = recovery_timer_range
	spawn_timer_init()

func on_buildup_init() -> void:
	current_phase_name = "BUILD-UP"
	current_budget += builtup_budget
	
	buildup_timer.start()
	current_timer_range = buildup_timer_range
	spawn_timer_init()

func on_peak_init() -> void:
	current_phase_name = "PEAK"
	current_budget += peak_budget
	
	peak_timer.start()
	current_timer_range = peak_timer_range
	spawn_timer_init()

func spawn_timer_init() -> void:
	if not current_timer_range.is_empty():
		spawn_timer.wait_time = randf_range(current_timer_range[0], current_timer_range[1])
		spawn_timer.start()

func choose_enemy() -> void:
	var affordable_keys: Array[String] = []
	for enemy_name in ENEMY_POOL:
		if ENEMY_POOL[enemy_name]["cost"] <= current_budget:
			affordable_keys.append(enemy_name)
			
	if affordable_keys.is_empty():
		return
		
	var chosen_name: String = affordable_keys.pick_random()
	var chosen_enemy_data: Dictionary = ENEMY_POOL[chosen_name]
	
	current_budget -= chosen_enemy_data["cost"]
	spawn_enemy(chosen_enemy_data["scene"], chosen_enemy_data["motion"], chosen_name)

func spawn_manual_enemy(enemy_key: String) -> void:
	if ENEMY_POOL.has(enemy_key):
		var enemy_data: Dictionary = ENEMY_POOL[enemy_key]
		spawn_enemy(enemy_data["scene"], enemy_data["motion"], enemy_key)
	else:
		push_error("cannot spawn debug enemy: key '" + enemy_key + "' not found in ENEMY_POOL")

func spawn_enemy(enemy_scene: PackedScene, motion: String, card_name: String) -> void:
	var spawn_position: Vector2
	var instance: Node2D = enemy_scene.instantiate() as Node2D
	
	if motion == "floor":
		if spawnpoints_floor.is_empty():
			return
		spawn_position = (spawnpoints_floor.pick_random() as Node2D).global_position
		instance.set("target_node", center)
	else:
		if spawnpoints_air.is_empty():
			return
		spawn_position = (spawnpoints_air.pick_random() as Node2D).global_position
		instance.set("target_node", center_air)
		
	instance.global_position = spawn_position
	instance.set("card_name", card_name)
	
	if instance.has_signal("died"):
		instance.connect("died", death_callback)
		
	enemy_container.add_child(instance)
	print_debug("Enemy spawned : " + card_name)

func update_debug_ui() -> void:
	if not debug_label or not debug_label.visible:
		return
		
	var cycle_left: String = "%.1f" % cicle_timer.time_left
	var spawn_left: String = "%.1f" % spawn_timer.time_left
	
	var phase_left: String = "0.0"
	if not recovery_timer.is_stopped(): 
		phase_left = "%.1f" % recovery_timer.time_left
	elif not buildup_timer.is_stopped(): 
		phase_left = "%.1f" % buildup_timer.time_left
	elif not peak_timer.is_stopped(): 
		phase_left = "%.1f" % peak_timer.time_left

	var timer_range_str: String = str(current_timer_range) if not current_timer_range.is_empty() else "[0, 0]"

	debug_label.text = (
		"=== DIRECTOR MONITOR ===\n" +
		"CURRENT PHASE: " + current_phase_name + " (" + phase_left + "s left)\n" +
		"CYCLE MASTER:  " + cycle_left + "s left\n" +
		"------------------------\n" +
		"MASTER BUDGET: " + str(budget) + "\n" +
		"WALLET POCKET: " + ("%.1f" % current_budget) + "\n" +
		"------------------------\n" +
		"NEXT SPAWN IN: " + spawn_left + "s\n" +
		"TIMER RANGE:   " + timer_range_str + "\n" +
		"DEBUG SPAWN:   Press F4 -> " + debug_enemy_to_spawn
	)

func _on_cicle_timeout() -> void:
	budget += budget_increase
	init()

func _on_spawn_timeout() -> void:
	if current_budget <= 0:
		spawn_timer.stop()
		return
	
	if not current_timer_range.is_empty():
		spawn_timer.wait_time = randf_range(current_timer_range[0], current_timer_range[1])
		spawn_timer.start()
	choose_enemy()

func _on_recovery_timeout() -> void:
	spawn_timer.stop()
	on_buildup_init()

func _on_buildup_timeout() -> void:
	spawn_timer.stop()
	on_peak_init()

func _on_peak_timeout() -> void:
	spawn_timer.stop()

func death_callback(card_name: String) -> void:
	if %HUD:
		%HUD.draw_enemy_card(card_name, ENEMY_POOL)
