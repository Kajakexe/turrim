extends Label

@export var fade_duration: float = 1.0

var _fade_tween: Tween

func _ready() -> void:
	modulate.a = 0.0

func fade_in() -> void:
	if _fade_tween and _fade_tween.is_running():
		_fade_tween.kill()

	visible = true
	modulate.a = 0.0

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, fade_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
