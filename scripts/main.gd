extends Node3D

const World = preload("res://scripts/world.gd")
const Drink = preload("res://scripts/drink.gd")
const Career = preload("res://scripts/career.gd")
const Hud = preload("res://scripts/hud.gd")
const PourEffect = preload("res://scripts/pour_effect.gd")
var world
var drink = Drink.new()
var career = Career.new()
var hud
var player: CharacterBody3D
var camera: Camera3D
var held_root: Node3D
var held = ""
var target = ""
var pouring = false
var mixing = false
var mix_progress = 0.0
var mix_container = ""
var mix_method = ""
var mix_last_angle = NAN
var shake_distance = 0.0
var shake_direction = 0.0
var shake_reversals = 0
var shake_segment = 0.0
var stream: Node3D
var state_seen = ""
var look_finger = -1
var garnish_index = 0
var toast_time = 0.0
var elapsed = 0.0

func _ready() -> void:
	world = World.new()
	add_child(world)
	world.build()
	player = CharacterBody3D.new()
	add_child(player)
	var collision = CollisionShape3D.new()
	var capsule = CapsuleShape3D.new()
	capsule.radius = 0.23
	capsule.height = 1.7
	collision.shape = capsule
	collision.position.y = 0.85
	player.add_child(collision)
	player.position = Vector3(0.4,0.1,1.8)
	camera = Camera3D.new()
	player.add_child(camera)
	camera.position.y = 1.65
	camera.rotation.x = -0.33
	camera.fov = 78
	camera.current = true
	held_root = Node3D.new()
	camera.add_child(held_root)
	held_root.position = Vector3(0.32,-0.39,-0.60)
	stream = PourEffect.new()
	add_child(stream)
	hud = Hud.new()
	add_child(hud)
	hud.action.connect(handle_action)
	hud.pour_changed.connect(func(value): pouring = value and active())
	var save_ok = career.load_game()
	show_menu()
	if not save_ok:
		hud.hint_label.text = "Save unreadable. Starting a new career."

func active() -> bool:
	return career.state == "playing" and not career.paused

func show_menu() -> void:
	career.state = "menu"
	career.paused = false
	reset_controls()
	hud.show_dialog("Behind the Bar 3D", "A real 3D first-person bartending prototype.\n\nMove with the left pad. Drag the world to look. Aim the crosshair at an object, then Pick / use.\n\nCareer: %d XP • €%.2f tips\nThe Copper Fox: playable. More venues: future content." % [career.xp,career.tips], {"Learn the craft (untimed)":"practice","Start a 3-minute shift":"start"})

func start_game(practice: bool) -> void:
	career.start(practice)
	drink.clear()
	set_held("")
	state_seen = "playing"
	hud.hide_dialog()
	note("Aim at GIN and pick it up. Aim at GLASS, then hold POUR.",8.0)

func reset_controls() -> void:
	pouring = false
	mixing = false
	look_finger = -1
	if hud != null:
		hud.movement = Vector2.ZERO
		hud.move_finger = -1

func set_held(item: String) -> void:
	if held in ["glass","jigger","shaker"]:
		var old = world.interactables[held]
		old.visible = true
		for child in old.get_children():
			if child is StaticBody3D:
				child.collision_layer = 1
	for child in held_root.get_children():
		held_root.remove_child(child)
		child.queue_free()
	held = item
	mixing = false
	pouring = false
	if World.COLORS.has(held):
		world.bottle(held_root,held,Vector3.ZERO)
	elif held in ["glass","jigger","shaker"]:
		var vessel_model = world.vessel(held_root,held,Vector3.ZERO)
		if held == "glass": world.glass_shape(vessel_model,drink.glass_type)
		var original = world.interactables[held]
		original.visible = false
		for child in original.get_children():
			if child is StaticBody3D:
				child.collision_layer = 0
		if held == "glass" and drink.volume("glass") > 0.0:
			var coupe = drink.glass_type == "coupe"
			var height = drink.volume("glass")/350.0*(0.10 if coupe else 0.22)
			world.cylinder(held_root,Vector3(0,(0.145 if coupe else 0.025)+height/2.0,0),0.072,height,Color("dcb96f"))
	if not held.is_empty():
		world.box(held_root,Vector3(0.045,0.11,0.035),Vector3(0.085,0.08,0.11),Color("bd926e"))
		world.box(held_root,Vector3(0.08,-0.045,0.095),Vector3(0.085,0.24,0.09),Color("315142"))

func ray_target() -> String:
	var from = camera.global_position
	var to = from - camera.global_basis.z * 3.1
	var query = PhysicsRayQueryParameters3D.create(from,to)
	query.exclude = [player.get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ""
	return str(hit.collider.get_meta("item", ""))

func handle_action(command: String) -> void:
	match command:
		"practice": start_game(true)
		"start": start_game(false)
		"menu": show_menu()
		"resume":
			career.paused = false
			hud.hide_dialog()
			state_seen = ""
		"pause": pause_game()
		"next":
			career.order += 1
			career.next_order()
			drink.clear()
			set_held("")
			hud.hide_dialog()
			state_seen = "playing"
		"use":
			if active(): use_target()
		"drop":
			if active(): set_held("")
		"discard":
			if active():
				drink.clear()
				set_held("")
				note("Fresh containers. Career and current order kept.")
		"glass":
			if active():
				drink.glass_type = "coupe" if drink.glass_type == "highball" else "highball"
				if held == "glass": set_held("glass")
				note("Glass: " + drink.glass_type)
		"mix":
			if active(): begin_mix()

func use_target() -> void:
	if target == "customer":
		if held != "glass":
			note("Pick up your glass, then aim at the customer to serve.")
		else:
			career.serve(drink.quality(career.order))
			set_held("")
	elif target == "ice":
		var container = held if held in ["glass","shaker"] else "glass"
		drink.ice[container] = true
		note("Ice added to " + container)
	elif target == "garnish":
		drink.garnish = ["lime","orange","olive"][garnish_index % 3]
		garnish_index += 1
		note("Garnish: " + drink.garnish + ". Use again to cycle.")
	elif World.COLORS.has(target) or target in ["glass","jigger","shaker"]:
		set_held(target)
	else:
		note("Move closer and aim at a labelled object.")

func begin_mix() -> void:
	if mixing:
		mixing = false
		return
	mix_container = "shaker" if held == "shaker" else target
	if not mix_container in ["glass","shaker"] or drink.volume(mix_container) <= 0.0:
		note("Hold a filled shaker, or aim at a filled glass to stir.")
		return
	mix_method = "shake" if held == "shaker" else "stir"
	mix_progress = 0.0
	mix_last_angle = NAN
	shake_distance = 0.0
	shake_direction = 0.0
	shake_reversals = 0
	shake_segment = 0.0
	mixing = true
	note("Drag back and forth to shake." if mix_method == "shake" else "Draw circles around the crosshair to stir.",10.0)

func _physics_process(delta: float) -> void:
	if not active():
		return
	var movement = hud.movement
	if Input.is_physical_key_pressed(KEY_W): movement.y -= 1
	if Input.is_physical_key_pressed(KEY_S): movement.y += 1
	if Input.is_physical_key_pressed(KEY_A): movement.x -= 1
	if Input.is_physical_key_pressed(KEY_D): movement.x += 1
	movement = movement.limit_length()
	var direction = player.transform.basis * Vector3(movement.x,0,movement.y)
	player.velocity.x = direction.x * 2.0
	player.velocity.z = direction.z * 2.0
	if not player.is_on_floor(): player.velocity.y -= 15.0 * delta
	else: player.velocity.y = 0.0
	player.move_and_slide()

func _process(delta: float) -> void:
	if camera == null: return
	elapsed += delta
	if active():
		target = ray_target()
		if pouring:
			if target in ["glass","jigger","shaker"] and World.COLORS.has(held):
				drink.pour(held,20.0 * minf(delta,0.1),target)
			elif held in ["jigger","shaker"] and target in ["glass","shaker"]:
				drink.transfer(held,target)
				pouring = false
	career.tick(minf(delta,0.2))
	if not career.paused and career.state != state_seen:
		state_seen = career.state
		if career.state in ["feedback","results"]:
			reset_controls()
			if not career.save_game(): note("Unable to save career on this device.")
			if career.state == "feedback":
				var r = career.result
				var body = "Customer ran out of patience." if r.expired else "Quality: %d/100 • Tip: €%.2f • +%d XP\n\n" % [r.quality,r.tip,r.xp]
				if not r.expired:
					for key in drink.breakdown(career.order):
						body += "%s: %d\n" % [key,drink.breakdown(career.order)[key]]
				hud.show_dialog("Order finished",body,{"Next customer":"next","Back to menu":"menu"})
			else:
				hud.show_dialog("Shift complete","Drinks served: %d\nTips: €%.2f\nCareer: %d XP\n\nNext venue qualification: 200 XP. Additional venues are future content." % [career.served,career.shift_tips,career.xp],{"Another shift":"start","Back to menu":"menu"})
	world.update_drink(drink)
	var pouring_now = active() and pouring and target in ["glass","jigger","shaker"] and World.COLORS.has(held)
	held_root.rotation.z = lerp_angle(held_root.rotation.z, -1.65 if pouring_now else 0.0, minf(1.0,delta*12.0))
	held_root.position.x = 0.32 + (sin(elapsed*28.0)*0.06 if mixing and mix_method == "shake" else 0.0)
	var from = held_root.to_global(Vector3(0,0.457,0))
	var to = from
	if pouring_now:
		to = world.interactables[target].global_position + Vector3(0,0.2,0)
		if target == "glass":
			to = world.liquid_mesh.global_position + Vector3(0,world.liquid_mesh.scale.y * 0.0025,0)
	stream.update_flow(minf(delta,0.05), pouring_now, from, to, World.COLORS.get(held,Color("ecdca9")))
	update_hud(delta)

func update_hud(delta: float) -> void:
	var recipe = Drink.RECIPES[career.order % 5]
	var order_text = recipe.name + "\n"
	for ingredient in recipe.liquid:
		order_text += "%s: %d / %d ml\n" % [ingredient.capitalize(),drink.liquid.glass.get(ingredient,0),recipe.liquid[ingredient]]
	order_text += "%s • ice • %s • %s" % [recipe.glass,recipe.method,recipe.garnish]
	hud.order_label.text = order_text
	hud.stats_label.text = ("PRACTICE" if career.practice else "%02d:%02d" % [int(career.time_left)/60,int(career.time_left)%60]) + "  €%.2f  %d XP" % [career.shift_tips,career.xp]
	hud.target_label.text = ("• " + target.to_upper()) if not target.is_empty() else ""
	hud.readout.text = "Holding: %s\nGlass %d ml • Jigger %d ml • Shaker %d ml\n%s • %s • Spilled %d ml" % [held.capitalize() if held != "" else "nothing",drink.volume("glass"),drink.volume("jigger"),drink.volume("shaker"),drink.glass_type,drink.garnish,drink.spilled]
	if mixing: hud.readout.text += "\n%s: %d%%" % [mix_method.capitalize(),mini(100,int(mix_progress*100))]
	toast_time = maxf(0.0,toast_time-delta)
	if toast_time == 0.0:
		hud.hint_label.text = "Aim at a bottle → pick up → aim at glass → hold POUR. Ice and garnish at the right end."

func note(message: String, duration: float = 4.0) -> void:
	hud.hint_label.text = message
	toast_time = duration

func pause_game() -> void:
	if not career.state in ["playing","feedback"] or career.paused: return
	career.paused = true
	reset_controls()
	hud.show_dialog("On a break","Your shift and current drink are paused.",{"Resume":"resume","Back to menu":"menu"})

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if hud != null: pause_game()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE: pause_game()
		if event.keycode == KEY_E and active(): use_target()
	if not active(): return
	if event is InputEventScreenTouch:
		if event.pressed and look_finger == -1:
			look_finger = event.index
		elif not event.pressed and event.index == look_finger:
			look_finger = -1
	elif event is InputEventScreenDrag and event.index == look_finger:
		look_or_mix(event.relative,event.position)
	elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		look_or_mix(event.relative,event.position)

func look_or_mix(relative: Vector2, screen_position: Vector2) -> void:
	if mixing:
		if mix_method == "shake":
			if absf(relative.x) > 2.0:
				var direction = signf(relative.x)
				if direction != shake_direction:
					if shake_segment >= 35.0: shake_reversals += 1
					shake_segment = 0.0
					shake_direction = direction
				shake_segment += absf(relative.x)
				shake_distance += absf(relative.x)
			mix_progress = minf(shake_distance/1000.0,shake_reversals/8.0)
		else:
			var offset = screen_position-get_viewport().get_visible_rect().size/2.0
			if offset.length() > 40.0 and offset.length() < 250.0:
				var angle = offset.angle()
				if is_finite(mix_last_angle):
					mix_progress += absf(wrapf(angle-mix_last_angle,-PI,PI))/(TAU*3.0)
				mix_last_angle = angle
			else:
				mix_last_angle = NAN
		if mix_progress >= 1.0:
			drink.method[mix_container] = mix_method
			mixing = false
			note("Mixed. Aim at GLASS and pour to strain a held shaker.")
		return
	player.rotation.y -= relative.x*0.003
	camera.rotation.x = clampf(camera.rotation.x-relative.y*0.003,-1.25,1.1)
