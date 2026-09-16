extends RefCounted

const SAVE_PATH = "user://career.json"
var xp = 0
var tips = 0.0
var shifts = 0
var practice = false
var paused = false
var state = "menu"
var time_left = 180.0
var patience = 90.0
var order = 0
var served = 0
var shift_tips = 0.0
var result = {}

func start(is_practice: bool) -> void:
	practice = is_practice
	paused = false
	time_left = 180.0
	order = 0
	served = 0
	shift_tips = 0.0
	next_order()

func next_order() -> void:
	patience = 90.0
	state = "playing"
	result = {}

func tick(delta: float) -> void:
	if paused or practice or not state in ["playing", "feedback"]:
		return
	time_left = maxf(0.0, time_left - delta)
	if time_left <= 0.0:
		state = "results"
		shifts += 1
	elif state == "playing":
		patience = maxf(0.0, patience - delta)
		if patience <= 0.0:
			result = {"quality":0,"tip":0.0,"xp":0,"expired":true}
			state = "feedback"

func serve(quality: int) -> void:
	if state != "playing" or paused:
		return
	quality = clampi(quality, 0, 100)
	var tip = snappedf(5.0 * quality / 100.0 * (0.5 + patience / 180.0), 0.01) if quality >= 50 else 0.0
	var earned_xp = roundi(quality / 5.0)
	xp += earned_xp
	tips += tip
	shift_tips += tip
	served += 1
	result = {"quality":quality,"tip":tip,"xp":earned_xp,"expired":false}
	state = "feedback"

func save_game() -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version":1,"xp":xp,"tips":tips,"shifts":shifts}))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return true
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1:
		return false
	for key in ["xp", "tips", "shifts"]:
		var value = data.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0:
			return false
	xp = int(data.xp)
	tips = float(data.tips)
	shifts = int(data.shifts)
	return true
