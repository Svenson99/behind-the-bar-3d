extends SceneTree

func _initialize() -> void: call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_game(true)
	await physics_frame
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.set_held("gin")
	scene.pouring = true
	for i in range(60): scene.update_pouring(0.016)
	assert(scene.drink.volume("glass") > 0, "Default station must allow catching a physical stream")
	var stock_before = scene.stock.gin
	var glass_before = scene.drink.volume("glass")
	scene.aim_offset.x = 0.7
	for i in range(90): scene.update_pouring(0.016)
	assert(scene.drink.spilled > 0, "Moving stream away must spill")
	assert(scene.stock.gin < stock_before, "Missed pours still consume stock")
	assert(scene.career.waste > 0)
	assert(scene.drink.volume("glass") < glass_before + 8, "Stream must not bend back to glass")
	scene.pause_game()
	stock_before = scene.stock.gin
	scene.update_pouring(0.05)
	assert(scene.stock.gin == stock_before)
	assert(not scene.sound.pour.playing)
	scene.handle_action("resume")
	scene.set_held("glass")
	scene.drop_glass()
	assert(scene.career.breakages == 1)
	assert(scene.drink.volume("glass") == 0)
	assert(scene.held == "")
	print("PASS: actual scene catches/misses liquid, consumes stock, pauses audio and drops glass")
	quit(0)
