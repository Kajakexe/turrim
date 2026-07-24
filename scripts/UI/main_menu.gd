extends Control

signal game_start

@export_group("Card Hover FX")
@export var hover_scale: Vector2 = Vector2(1.15, 1.15)
@export var hover_scale_menu: Vector2 = Vector2(1.08, 1.08)
@export var hover_rotation_deg: float = 6.0
@export var anim_duration: float = 0.25

@export_group("Tooltip FX")
@export var tooltip_offset: float = 120.0
@export var tooltip_v_offset: float = -20.0

@export_group("Audio")
@export var hover_sound: AudioStream

@onready var menu_container: VBoxContainer = $MenuContainer
@onready var tooltips_container: Control = $ToolTips

var card_tweens: Dictionary = {}
var tooltip_tweens: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var cards_container: Container = $MenuContainer/cards
	cards_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltips_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	for tooltip in tooltips_container.get_children():
		if tooltip is Control:
			tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
			tooltip.scale = Vector2.ZERO
			tooltip.pivot_offset = tooltip.size / 2.0
			tooltip.visible = false

	for wrapper in cards_container.get_children():
		if wrapper is Control:
			_setup_element(wrapper, true)

	for wrapper in menu_container.get_children():
		if wrapper is Control and wrapper.name != "cards":
			_setup_element(wrapper, false)

func _setup_element(wrapper: Control, is_card: bool) -> void:
	wrapper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var node_name: String = wrapper.name
	var texture_rect: TextureRect = wrapper.get_node_or_null(node_name) as TextureRect
	
	if texture_rect:
		wrapper.custom_minimum_size = texture_rect.size
		texture_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		texture_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		texture_rect.pivot_offset = texture_rect.size / 2.0
		
		texture_rect.mouse_entered.connect(_on_hover_entered.bind(node_name, texture_rect, is_card))
		texture_rect.mouse_exited.connect(_on_hover_exited.bind(node_name, texture_rect))
		
		if node_name == "play":
			texture_rect.gui_input.connect(_on_play_gui_input)

func _on_hover_entered(element_name: String, tex: TextureRect, is_card: bool) -> void:
	var tooltip: Control = tooltips_container.get_node_or_null(element_name) as Control
	if tooltip:
		_update_tooltip_position(tex, tooltip)

	var target_scale: Vector2 = hover_scale if is_card else hover_scale_menu
	
	_kill_tween(card_tweens, element_name)
	var c_tween: Tween = create_tween().set_parallel(true)
	card_tweens[element_name] = c_tween
	
	c_tween.tween_property(tex, "scale", target_scale, anim_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		
	if is_card:
		var index: int = tex.get_parent().get_index()
		# alternate tilt direction based on index
		var tilt_dir: float = -1.0 if (index % 2 == 0) else 1.0
		c_tween.tween_property(tex, "rotation_degrees", hover_rotation_deg * tilt_dir, anim_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			
	AudioManager.play_sfx(hover_sound)

	if tooltip:
		tooltip.pivot_offset = tooltip.size / 2.0
		tooltip.visible = true
		
		_kill_tween(tooltip_tweens, element_name)
		var t_tween: Tween = create_tween()
		tooltip_tweens[element_name] = t_tween
		
		t_tween.tween_property(tooltip, "scale", Vector2.ONE, anim_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_hover_exited(element_name: String, tex: TextureRect) -> void:
	_kill_tween(card_tweens, element_name)
	var c_tween: Tween = create_tween().set_parallel(true)
	card_tweens[element_name] = c_tween
	
	c_tween.tween_property(tex, "scale", Vector2.ONE, anim_duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	c_tween.tween_property(tex, "rotation_degrees", 0.0, anim_duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var tooltip: Control = tooltips_container.get_node_or_null(element_name) as Control
	if tooltip:
		_kill_tween(tooltip_tweens, element_name)
		var t_tween: Tween = create_tween()
		tooltip_tweens[element_name] = t_tween
		
		t_tween.tween_property(tooltip, "scale", Vector2.ZERO, anim_duration * 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t_tween.tween_callback(func(): tooltip.visible = false)

func _on_play_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_play_pressed()

func _on_play_pressed() -> void:
	print("play button clicked!")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	game_start.emit()

func _update_tooltip_position(card_tex: TextureRect, tooltip: Control) -> void:
	var wrapper: Control = card_tex.get_parent() as Control
	var ref_rect: Rect2 = wrapper.get_global_rect() if wrapper else card_tex.get_global_rect()
	var viewport_width: float = get_viewport_rect().size.x
	
	var target_global_pos: Vector2 = Vector2(
		ref_rect.position.x + ref_rect.size.x + tooltip_offset,
		ref_rect.position.y + (ref_rect.size.y / 2.0) - (tooltip.size.y / 2.0) + tooltip_v_offset
	)
	
	# keep tooltip on screen if past right edge
	if target_global_pos.x + tooltip.size.x > viewport_width:
		target_global_pos.x = ref_rect.position.x - tooltip.size.x - tooltip_offset

	tooltip.position = target_global_pos - tooltips_container.global_position

func _kill_tween(dict: Dictionary, key: String) -> void:
	if dict.has(key) and dict[key] is Tween and dict[key].is_running():
		dict[key].kill()
