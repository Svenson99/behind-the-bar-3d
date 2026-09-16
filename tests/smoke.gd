extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await physics_frame
	assert(scene.camera is Camera3D, "Actual perspective camera required")
	assert(scene.world.interactables.size() >= 13, "3D interactables must exist")
	assert(scene.hud.modal.visible, "Main menu must be visible")
	scene.start_game(true)
	await process_frame
	assert(scene.active())
	scene.target = "gin"
	scene.use_target()
	assert(scene.held == "gin")
	scene.drink.pour("gin",50.0,"glass")
	scene.drink.pour("tonic",150.0,"glass")
	scene.drink.ice.glass = true
	scene.drink.garnish = "lime"
	scene.set_held("glass")
	scene.target = "customer"
	scene.use_target()
	await process_frame
	assert(scene.career.result.quality == 100)
	assert(scene.hud.modal.visible)
	scene.start_game(false)
	scene.pause_game()
	assert(scene.career.paused)
	assert(not scene.pouring)
	assert(scene.hud.movement == Vector2.ZERO)
	print("PASS: scene boots, 3D camera/items exist, perfect order serves, pause cancels controls")
	quit(0)
