extends Node

@onready var http_request: HTTPRequest = $HTTPRequest

const BASE_URL = "https://YourURLPointingtoPocketBaseBackend"
const PASSCODE = "Password123!"

signal scores_loaded(scores_list: Array)
signal score_submitted(success: bool)

func _ready() -> void:
	if http_request:
		http_request.request_completed.connect(_on_request_completed)

func submit_score(player_name: String, final_score: int) -> void:
	var payload = {
		"username": player_name,
		"score": final_score,
		"passcode": PASSCODE
	}
	
	var json_data = JSON.stringify(payload)
	var headers = ["Content-Type: application/json"]
	
	var error = http_request.request(BASE_URL, headers, HTTPClient.METHOD_POST, json_data)
	if error != OK:
		print("Error initializing HTTP request: ", error)

func fetch_top_scores(limit: int = 10) -> void:
	# get top scores sorted descending
	var url = BASE_URL + "?sort=-score&perPage=" + str(limit)
	var error = http_request.request(url)
	if error != OK:
		print("Error fetching leaderboard: ", error)

func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code in [200, 201]:
		var response = JSON.parse_string(body.get_string_from_utf8())
		if response == null:
			print("JSON Parse Error")
			return
			
		# fetch response contains items array
		if response is Dictionary and response.has("items"):
			var scores = []
			for item in response["items"]:
				scores.append({
					"username": item.get("username", "Anonymous"),
					"score": item.get("score", 0)
				})
			
			print("--- SCORES LOADED SUCCESSFULLY ---")
			print(scores)
			scores_loaded.emit(scores)
		else:
			print("Score submitted successfully!")
			score_submitted.emit(true)
			
	elif response_code == 400:
		print("Submission rejected! Invalid passcode or score limit exceeded.")
		score_submitted.emit(false)
	else:
		print("Server error code: ", response_code)
		score_submitted.emit(false)
