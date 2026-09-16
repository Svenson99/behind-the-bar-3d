extends SceneTree

var screen: SubViewport

func touch(index: int, position: Vector2, down: bool, canceled: bool = false) -> void:
	var event = InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = down
	event.canceled = canceled
	screen.push_input(event, true)

func find_button(node: Node, caption: String) -> Button:
	if node is Button and node.text == caption:
		return node
	for child in node.get_children():
		var result = find_button(child, caption)
		if result != null:
			return result
	return null

func center(button: Button) -> Vector2:
	return button.get_global_rect().get_center()

func require(condition: bool, message: String) -> bool:
	if not condition:
		push_error(message)
		quit(1)
	return condition

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	screen = SubViewport.new()
	screen.size = Vector2i(1280,720)
	screen.handle_input_locally = true
	root.add_child(screen)
	var game = load("res://main.tscn").instantiate()
	screen.add_child(game)
	for frame in range(5):
		await process_frame
	var learn = find_button(game.hud.root,"Learn the craft (untimed)")
	if not require(learn != null,"Practice button must exist"): return
	touch(0,center(learn),true)
	touch(0,center(learn),false)
	await process_frame
	if not require(game.active(),"A real ScreenTouch tap must start practice"): return
	var pour = find_button(game.hud.root,"HOLD TO POUR")
	# First finger stays on the movement pad; second finger operates a button.
	touch(0,Vector2(131,485),true)
	if not require(game.hud.movement.length()>0.1,"First finger moves player"): return
	touch(1,center(pour),true)
	if not require(game.pouring,"Second finger must start pouring"): return
	touch(2,Vector2(700,240),true)
	touch(2,Vector2(700,240),false)
	if not require(game.pouring,"Unrelated finger release must not stop pouring"): return
	touch(1,Vector2(800,460),false)
	if not require(not game.pouring,"Release outside the button must stop pouring"): return
	touch(0,Vector2(131,485),false)
	if not require(game.hud.movement == Vector2.ZERO,"Movement stops on release"): return
	var pause = find_button(game.hud.root,"Pause")
	touch(0,center(pause),true)
	touch(0,center(pause),false,true)
	if not require(not game.career.paused,"Canceled touch must not activate a button"): return
	touch(0,center(pause),true)
	touch(0,center(pause),false)
	await process_frame
	if not require(game.career.paused,"Touch pause opens pause dialog"): return
	for frame in range(3):
		await process_frame
	var resume = find_button(game.hud.root,"Resume")
	touch(0,center(resume),true)
	touch(0,center(resume),false)
	if not require(not game.career.paused,"Touch resumes play"): return
	# Desktop mouse input continues to work too.
	var motion = InputEventMouseMotion.new()
	motion.position = center(pause)
	screen.push_input(motion,true)
	for down in [true,false]:
		var mouse = InputEventMouseButton.new()
		mouse.position = center(pause)
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = down
		screen.push_input(mouse,true)
	if not require(game.career.paused,"Desktop mouse still activates buttons"): return
	print("PASS: touch menu, multi-finger movement/pour, outside release, cancel, pause/resume and mouse")
	quit(0)
