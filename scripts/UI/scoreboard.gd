extends Control

@onready var labels_place: Array = $HBoxContainer/places.get_children()
@onready var labels_name: Array = $HBoxContainer/name.get_children()
@onready var labels_point: Array = $HBoxContainer/points.get_children()

func _ready() -> void:
	if %client and %client.has_signal("scores_loaded"):
		if not %client.scores_loaded.is_connected(_on_scores_loaded):
			%client.scores_loaded.connect(_on_scores_loaded)
	
	call_deferred("refresh_scores")

func refresh_scores() -> void:
	if %client and %client.has_method("fetch_top_scores"):
		%client.fetch_top_scores(6)

func _on_scores_loaded(scores: Array) -> void:
	update_scoreboard_ui(scores)

func update_scoreboard_ui(scores: Array) -> void:
	for i in range(labels_name.size()):
		var place_label: Label = labels_place[i] as Label if i < labels_place.size() else null
		var name_label: Label = labels_name[i] as Label if i < labels_name.size() else null
		var point_label: Label = labels_point[i] as Label if i < labels_point.size() else null
		
		if place_label:
			place_label.text = "%d" % [i + 1]
			
		if i < scores.size():
			var entry: Dictionary = scores[i]
			var player_name: String = str(entry.get("username", "---"))
			var player_score: int = int(entry.get("score", 0))
			
			if name_label:
				name_label.text = player_name
			if point_label:
				point_label.text = "%05d" % player_score
		else:
			if name_label:
				name_label.text = "---"
			if point_label:
				point_label.text = "---"
