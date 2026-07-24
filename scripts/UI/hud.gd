extends Control

@export_group("Card Texture Setup")
@export var card_spritesheet: Texture2D
@export var card_back_texture: Texture2D
@export var card_width: int = 64
@export var card_height: int = 96

@export_group("Animation & Stack Settings")
@export var anim_duration: float = 0.35
@export var scale_dur: float = 0.35
@export var max_stack_rotation_deg: float = 12.0
@export var max_stack_offset_px: float = 6.0
@export var max_discard_stack_count: int = 300

@export_group("Game Over Settings")
@export var score_label: Label

@export var card_collect_sfx: AudioStream
@export var card_counted_sfx: AudioStream

@export var card_falling_sfx: AudioStream
var active_engine_player: AudioStreamPlayer

@export var card_drop_interval: float = 0.4
@export var fall_anim_duration: float = 1.5
@export var max_tumble_spin_deg: float = 180.0
@export var name_input_field: LineEdit

@export_subgroup("Game Over Acceleration")
@export var min_card_drop_interval: float = 0.03
@export var min_fall_anim_duration: float = 0.4
@export var acceleration_curve: float = 1.5

var _nametag_regex := RegEx.new()

@onready var score_info = $GameOver/game_over_info

@onready var draw_marker: Marker2D = $draw_marker
@onready var active_marker: Marker2D = $active_marker
@onready var discard_marker: Marker2D = $discard_marker

@onready var active_card: TextureRect = $CardDisplay
@onready var discard_container: Control = $DiscardStack

var current_tween: Tween

var current_animating_card_data: Dictionary = {}
var current_target_discard_pos: Vector2 = Vector2.ZERO
var current_target_rotation: float = 0.0

var _is_game_over: bool = false
var total_score: int = 0

func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed:
		if event.keycode == KEY_F5:
			_spawn_dummy_stack(50)
			trigger_game_over_card_drop()

func _spawn_dummy_stack(count: int) -> void:
	if discard_container.get_child_count() > 0:
		return
		
	for i in range(count):
		var dummy_tex: AtlasTexture = _get_atlas_for_frame(0)
		var rand_rot: float = deg_to_rad(randf_range(-max_stack_rotation_deg, max_stack_rotation_deg))
		var rand_pos: Vector2 = discard_marker.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		_add_card_to_discard_stack(dummy_tex, rand_pos, rand_rot, 1)

func _ready() -> void:
	_setup_card_rect(active_card)
	active_card.visible = false
	_nametag_regex.compile("[^a-zA-Z0-9]")

func _setup_card_rect(card: TextureRect) -> void:
	card.custom_minimum_size = Vector2(card_width, card_height)
	card.size = Vector2(card_width, card_height)
	card.pivot_offset = Vector2(card_width / 2.0, card_height / 2.0)

func draw_enemy_card(enemy_key: String, enemy_pool: Dictionary) -> void:
	if _is_game_over:
		return
		
	var card_data: Dictionary = CardDatabase.get_card_data_for_enemy(enemy_key, enemy_pool)
	if card_data.is_empty():
		return
	_animate_card_draw_and_flip(card_data)

func _animate_card_draw_and_flip(card_data: Dictionary) -> void:
	if current_tween and current_tween.is_running():
		current_tween.kill()
		if not current_animating_card_data.is_empty():
			var prev_card_val: int = current_animating_card_data.get("cost", current_animating_card_data.get("value", 1))
			var card_tex = _get_atlas_for_frame(current_animating_card_data["frame"])
			_add_card_to_discard_stack(card_tex, current_target_discard_pos, current_target_rotation, prev_card_val)

	var card_center_offset: Vector2 = Vector2(card_width / 2.0, card_height / 2.0)
	var draw_pos: Vector2 = draw_marker.global_position - card_center_offset
	var active_pos: Vector2 = active_marker.global_position - card_center_offset
	var base_discard_pos: Vector2 = discard_marker.global_position - card_center_offset

	var random_rotation_rad: float = deg_to_rad(randf_range(-max_stack_rotation_deg, max_stack_rotation_deg))
	var random_offset: Vector2 = Vector2(
		randf_range(-max_stack_offset_px, max_stack_offset_px),
		randf_range(-max_stack_offset_px, max_stack_offset_px)
	)
	var target_discard_pos: Vector2 = base_discard_pos + random_offset

	current_animating_card_data = card_data
	current_target_discard_pos = target_discard_pos
	current_target_rotation = random_rotation_rad

	_setup_card_rect(active_card)
	active_card.texture = card_back_texture
	active_card.global_position = draw_pos
	active_card.rotation = 0.0
	active_card.scale = Vector2.ONE
	
	active_card.z_index = discard_container.get_child_count() + 10
	active_card.visible = true

	current_tween = create_tween()

	current_tween.set_parallel(true)
	current_tween.tween_property(active_card, "global_position", active_pos, anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.tween_property(active_card, "scale:x", 0.0, anim_duration * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	current_tween.chain().tween_callback(func():
		active_card.texture = _get_atlas_for_frame(card_data["frame"])
	)

	current_tween.tween_property(active_card, "scale:x", 1.0, anim_duration * 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	current_tween.chain().tween_callback(func():
		_play_card_flip_sound()
	)
	
	current_tween.tween_property(active_card, "scale", Vector2(1.15, 1.15), scale_dur * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	current_tween.chain().tween_property(active_card, "scale", Vector2(1.0, 1.0), scale_dur * 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	current_tween.chain().tween_interval(0.6)

	current_tween.chain().set_parallel(true)
	current_tween.tween_property(active_card, "global_position", target_discard_pos, anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(active_card, "rotation", random_rotation_rad, anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	current_tween.tween_property(active_card, "scale", Vector2(0.85, 0.85), anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	current_tween.chain().tween_callback(func():
		var card_val: int = card_data.get("cost", card_data.get("value", 1))
		_add_card_to_discard_stack(active_card.texture, target_discard_pos, random_rotation_rad, card_val)
		active_card.visible = false
		current_animating_card_data.clear()
	)

func _play_card_flip_sound() -> void:
	AudioManager.play_sfx(card_collect_sfx)

func _add_card_to_discard_stack(card_tex: Texture2D, target_pos: Vector2, target_rot: float, card_value: int = 1) -> void:
	var stacked_card: TextureRect = TextureRect.new()
	_setup_card_rect(stacked_card)
	stacked_card.texture = card_tex
	stacked_card.set_meta("card_value", card_value)

	discard_container.add_child(stacked_card)
	stacked_card.z_as_relative = false
	stacked_card.z_index = discard_container.get_child_count()
	stacked_card.rotation = target_rot
	stacked_card.scale = Vector2(0.85, 0.85)
	stacked_card.global_position = target_pos

	if discard_container.get_child_count() > max_discard_stack_count:
		var oldest_card = discard_container.get_child(0)
		oldest_card.queue_free()

func _get_atlas_for_frame(frame_index: int) -> AtlasTexture:
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = card_spritesheet
	atlas.region = Rect2(frame_index * card_width, 0, card_width, card_height)
	return atlas

func trigger_game_over_card_drop() -> void:
	_is_game_over = true
	
	if current_tween and current_tween.is_running():
		current_tween.kill()
		active_card.visible = false

	total_score = 0
	if score_label:
		score_label.text = "%05d" % 0

	var stack_cards: Array[Node] = discard_container.get_children()
	var total_cards: int = stack_cards.size()
	if total_cards == 0:
		if name_input_field:
			name_input_field.grab_focus()
		return

	stack_cards.reverse()

	active_engine_player = AudioManager.play_looping_sfx(card_falling_sfx)

	var sequence_tween: Tween = create_tween().set_parallel(false)
	var max_ramp_cards: float = 30.0

	for i in range(total_cards):
		var top_card := stack_cards[i] as TextureRect
		if not top_card:
			continue

		var progress: float = clampf(float(i) / max_ramp_cards, 0.0, 1.0)
		var curved_progress: float = pow(progress, acceleration_curve)

		var current_fall_duration: float = lerp(fall_anim_duration, min_fall_anim_duration, curved_progress)
		var current_interval: float = lerp(card_drop_interval, min_card_drop_interval, curved_progress)
		var target_pitch: float = lerp(1.0, 2.0, curved_progress)

		var card_val: int = top_card.get_meta("card_value", 1)
		var start_pos: Vector2 = top_card.global_position
		var target_pos: Vector2 = start_pos + Vector2(randf_range(-60.0, 60.0), 1000.0)

		var spin_dir: float = -1.0 if randf() < 0.5 else 1.0
		var target_rot: float = top_card.rotation + (deg_to_rad(randf_range(90.0, max_tumble_spin_deg)) * spin_dir)

		sequence_tween.tween_callback(func(c = top_card, pos = target_pos, rot = target_rot, val = card_val, fall_dur = current_fall_duration, pitch = target_pitch):
			if not is_instance_valid(c):
				return
			
			c.z_index = 100

			if active_engine_player and is_instance_valid(active_engine_player):
				active_engine_player.pitch_scale = pitch
			
			var card_drop_tween: Tween = create_tween().set_parallel(true)
			card_drop_tween.tween_property(c, "global_position", pos, fall_dur).set_trans(Tween.TRANS_LINEAR)
			card_drop_tween.tween_property(c, "rotation", rot, fall_dur).set_trans(Tween.TRANS_LINEAR)

			card_drop_tween.chain().tween_callback(func():
				if is_instance_valid(c):
					_add_value_to_score(val)
					c.queue_free()
			)
		)

		sequence_tween.tween_interval(current_interval)

	sequence_tween.chain().tween_callback(func():
		if name_input_field:
			name_input_field.grab_focus()
		
		if score_info and score_info.has_method("fade_in"):
			score_info.fade_in()
		
		if active_engine_player:
			AudioManager.stop_sfx(active_engine_player)
			active_engine_player = null
	)

func _add_value_to_score(value: int) -> void:
	total_score += value
	if not score_label:
		return

	AudioManager.play_sfx(card_counted_sfx)

	score_label.text = "%05d" % total_score

	var pop_tween: Tween = create_tween()
	pop_tween.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(score_label, "scale", Vector2.ONE, 0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _on_nametag_text_changed(new_text: String) -> void:
	var cleaned_text := _nametag_regex.sub(new_text, "", true)
	
	if cleaned_text != new_text:
		name_input_field.text = cleaned_text
		name_input_field.caret_column = cleaned_text.length()

func _on_nametag_text_submitted(new_text: String) -> void:
	var cleaned_text := _nametag_regex.sub(new_text.strip_edges(), "", true)
	
	if cleaned_text.is_empty():
		print("Name cannot be empty or contain only special characters!")
		return

	name_input_field.set_deferred("editable", false)

	%client.submit_score(cleaned_text, total_score)
	get_tree().current_scene.reload_init()
