extends RefCounted

const SAVE_PATH = "user://career.json"
const VENUES = ["The Copper Fox", "Velvet Lounge", "Skyline Terrace"]
const UNLOCKS = [0, 120, 300]
const NAMES = ["Alex", "Morgan", "Sam", "Robin", "Charlie", "Jamie", "Taylor", "Casey"]
var xp = 0
var tips = 0.0
var shifts = 0
var venue = 0
var practice = false
var paused = false
var state = "menu"
var time_left = 180.0
var patience = 90.0
var order = 0
var served = 0
var lost = 0
var waste = 0.0
var breakages = 0
var shift_tips = 0.0
var result = {}
var customers: Array[Dictionary] = []
var sequence = 0
var selected = 0

func start(is_practice: bool) -> void:
	practice = is_practice
	paused = false
	time_left = 180.0
	served = 0
	lost = 0
	waste = 0.0
	breakages = 0
	shift_tips = 0.0
	sequence = 0
	selected = 0
	state = "playing"
	result = {}
	customers.clear()
	for i in range(4):
		customers.append({"name":NAMES[i], "recipe":i, "patience":110.0, "state":"arriving", "timer":float(i * 9), "visit":i})
	sequence = 4
	customers[0].state = "waiting"
	select_customer(0)

func select_customer(seat: int) -> void:
	selected = clampi(seat, 0, 3)
	order = customers[selected].recipe
	patience = customers[selected].patience

func next_order() -> void:
	state = "playing"
	result = {}

func tick(delta: float) -> void:
	if paused or state != "playing": return
	var step = delta if practice else minf(delta, time_left)
	for p in customers:
		if p.state == "waiting":
			if not practice:
				p.patience = maxf(0, p.patience - step * (1.0 + venue * 0.18))
				if p.patience == 0:
					p.state = "leaving"
					p.timer = 4.0
					lost += 1
		else:
			p.timer -= step
			if p.timer <= 0:
				if p.state == "arriving":
					p.state = "waiting"
				elif p.state == "drinking":
					p.state = "leaving"
					p.timer = 4.0
				else:
					p.state = "arriving"
					p.timer = 7.0
					p.name = NAMES[sequence % NAMES.size()]
					p.recipe = (sequence * 3 + venue) % 5
					p.visit = sequence
					p.patience = 110.0
					sequence += 1
	select_customer(selected)
	if not practice:
		time_left = maxf(0, time_left - delta)
		if time_left == 0:
			state = "results"
			shifts += 1
			tips += maxf(0, shift_tips - costs())

func costs() -> float:
	return waste * 0.012 + breakages * 2.5

func serve_customer(seat: int, quality: int) -> bool:
	if state != "playing" or paused or customers[seat].state != "waiting": return false
	var p = customers[seat]
	quality = clampi(quality, 0, 100)
	var tip = snappedf((5.0 + venue * 2.0) * quality / 100.0 * (0.5 + p.patience / 220.0), 0.01) if quality >= 50 else 0.0
	var earned_xp = roundi(quality / 5.0) if not practice else 0
	xp += earned_xp
	shift_tips += tip
	served += 1
	result = {"quality":quality,"tip":tip,"xp":earned_xp,"expired":false}
	p.state = "drinking"
	p.timer = 14.0
	return true

func serve(quality: int) -> void:
	serve_customer(selected, quality)

func save_game() -> bool:
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"version":1,"xp":xp,"tips":tips,"shifts":shifts}))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return true
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary or data.get("version") != 1: return false
	for key in ["xp", "tips", "shifts"]:
		var value = data.get(key)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0: return false
	xp = int(data.xp)
	tips = float(data.tips)
	shifts = int(data.shifts)
	return true
