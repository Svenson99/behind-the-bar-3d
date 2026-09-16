extends Node3D

const World = preload("res://scripts/world.gd")
const Drink = preload("res://scripts/drink.gd")
const Career = preload("res://scripts/career.gd")
const Hud = preload("res://scripts/hud.gd")
const PourEffect = preload("res://scripts/pour_effect.gd")
const LiquidPhysics = preload("res://scripts/liquid_physics.gd")
const Sound = preload("res://scripts/audio.gd")
var sound
var stock = {}
var aim_offset = Vector2.ZERO
var landing = {}
var marker: MeshInstance3D
var recipe_page = 0
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
	sound = Sound.new()
	add_child(sound)
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
	marker = world.cylinder(self,Vector3.ZERO,0.032,0.002,Color("77d8b8"))
	marker.visible = false
	hud = Hud.new()
	add_child(hud)
	hud.action.connect(handle_action)
	hud.pour_changed.connect(func(value): pouring = value and active())
	var save_ok = career.load_game()
	hud.backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	show_menu()
	if not save_ok:
		hud.hint_label.text = "Save unreadable. Starting a new career."

func active() -> bool:
	return career.state == "playing" and not career.paused

func show_menu() -> void:
	career.state = "menu"
	career.paused = false
	reset_controls()
	if sound != null: sound.flow(false)
	hud.show_dialog("BEHIND THE BAR", "Clock in. Learn the craft. Earn your next bar.\n\nVenue: %s\nCareer: %d XP • €%.2f banked • %d shifts\n\nFour seats. Five cocktails. Your reputation." % [Career.VENUES[career.venue],career.xp,career.tips,career.shifts], {"Start shift":"start","Learn the craft (untimed)":"practice","Choose venue":"venues","Settings & help":"settings"})

func start_game(practice: bool) -> void:
	career.start(practice)
	stock.clear()
	for ingredient in World.COLORS: stock[ingredient] = 750.0
	world.set_venue(career.venue)
	drink.clear()
	set_held("")
	player.position = Vector3(0.4,0.1,1.05)
	player.rotation.y = 0
	camera.rotation.x = -0.4
	aim_offset = Vector2.ZERO
	state_seen = "playing"
	hud.hide_dialog()
	note("Select a seat ticket. Pick a bottle, hold POUR and drag to guide it. Green marker = inside a container.",10.0)

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
			var height = drink.volume("glass")/(150.0 if coupe else 350.0)*(0.10 if coupe else 0.22)
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
	sound.play("tap")
	if command.begins_with("seat_"):
		if active(): career.select_customer(int(command.trim_prefix("seat_")))
		return
	if command.begins_with("venue_"):
		var index = int(command.trim_prefix("venue_"))
		if career.xp >= Career.UNLOCKS[index]:
			career.venue = index
			world.set_venue(index)
			show_menu()
		return
	match command:
		"venues":
			var choices = {}
			var body = "Higher venues bring faster customers and larger tips.\n"
			for i in range(3):
				body += "\n%s — %d XP" % [Career.VENUES[i],Career.UNLOCKS[i]]
				if career.xp >= Career.UNLOCKS[i]: choices[Career.VENUES[i]] = "venue_%d" % i
			choices["Back"] = "menu"
			hud.show_dialog("YOUR CAREER",body,choices)
		"settings": show_settings()
		"sound":
			sound.enabled = not sound.enabled
			sound.apply_settings()
			show_settings()
		"music":
			sound.music_enabled = not sound.music_enabled
			sound.apply_settings()
			show_settings()
		"recipes":
			if active():
				career.paused = true
				reset_controls()
			show_recipe()
		"recipe_next":
			recipe_page = (recipe_page+1)%Drink.RECIPES.size()
			show_recipe()
		"break":
			if active() and held == "glass": drop_glass()
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
				career.waste += drink.volume("glass") + drink.volume("shaker") + drink.volume("jigger")
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
	if target.begins_with("customer"):
		var seat = int(target.trim_prefix("customer_")) if target != "customer" else 0
		if held != "glass":
			career.select_customer(seat)
			note("Seat %d selected. Pick up a finished glass and serve this customer." % [seat+1])
		else:
			var quality = drink.quality(career.customers[seat].recipe)
			if career.serve_customer(seat,quality):
				sound.play("serve")
				note("Seat %d: %d/100 • €%.2f tip. Other customers are still waiting!" % [seat+1,quality,career.result.tip],6.0)
				drink.clear()
				set_held("")
				career.save_game()
			else: note("This customer is not waiting for a drink.")
	elif target == "ice":
		var container = held if held in ["glass","shaker"] else "glass"
		drink.ice[container] = true
		sound.play("ice")
		note("Ice added to " + container)
	elif target == "garnish":
		drink.garnish = ["lime","orange","olive"][garnish_index % 3]
		garnish_index += 1
		note("Garnish: " + drink.garnish + ". Use again to cycle.")
	elif World.COLORS.has(target) or target in ["glass","jigger","shaker"]:
		set_held(target)
		sound.play("glass")
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
				hud.show_dialog("SHIFT COMPLETE","Served: %d • Walkouts: %d\nTips: €%.2f • Waste / breakages: €%.2f\nBanked this shift: €%.2f\nCareer: %d XP\n\nLounge unlocks at 120 XP • Terrace at 300 XP" % [career.served,career.lost,career.shift_tips,career.costs(),maxf(0,career.shift_tips-career.costs()),career.xp],{"Another shift":"start","Back to menu":"menu"})
	world.update_drink(drink)
	world.update_customers(career,elapsed)
	update_pouring(minf(delta,0.05))
	update_hud(delta)

func update_hud(delta: float) -> void:
	hud.title_label.text = "BEHIND THE BAR / " + Career.VENUES[career.venue].to_upper()
	if not career.customers.is_empty(): hud.update_tickets(career.customers,career.selected)
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
	if stock.has(held): hud.readout.text += " • Bottle: %d ml" % stock[held]
	toast_time = maxf(0.0,toast_time-delta)
	if toast_time == 0.0:
		hud.hint_label.text = "Select a seat ticket • Green pour marker = container • Release POUR before moving away"

func note(message: String, duration: float = 4.0) -> void:
	hud.hint_label.text = message
	toast_time = duration

func pause_game() -> void:
	if not career.state in ["playing","feedback"] or career.paused: return
	career.paused = true
	reset_controls()
	sound.flow(false)
	hud.show_dialog("ON A BREAK","Shift, customers and current drink are paused.",{"Resume":"resume","Recipe book":"recipes","Settings":"settings","End shift / menu":"menu"})

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
	if held == "glass" and relative.length() > 45 and drink.volume("glass") > 0:
		var before = drink.spilled
		drink.decant("glass","",minf(8.0,(relative.length()-45)*0.04))
		career.waste += drink.spilled-before
		note("Careful! Fast turns spill an open glass.",2.0)
	if pouring:
		aim_offset += relative * Vector2(0.0015,-0.0015)
		aim_offset = aim_offset.clamp(Vector2(-0.7,-0.2),Vector2(0.7,0.5))
		return
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

func show_settings() -> void:
	var back = "resume" if career.paused else "menu"
	hud.show_dialog("SETTINGS & CONTROLS", "Left pad: walk. Drag the world: look.\nHold POUR, then drag: move the bottle over a container.\nGreen marker catches liquid. Red marker spills it.\nPick up the glass and aim at the correct seated customer.\nDrop glass breaks it; waste and damage cost tips.",{"Sound: " + ("ON" if sound.enabled else "OFF"):"sound","Music: " + ("ON" if sound.music_enabled else "OFF"):"music","Back":back})

func show_recipe() -> void:
	var r = Drink.RECIPES[recipe_page]
	var body = ""
	for ingredient in r.liquid: body += "%s: %d ml\n" % [ingredient.capitalize(),r.liquid[ingredient]]
	body += "\n%s glass • %s • ice\nGarnish: %s" % [r.glass,r.method,r.garnish]
	hud.show_dialog(r.name,body,{"Next recipe":"recipe_next","Back to shift":"resume"})

func update_pouring(delta: float) -> void:
	var can_pour = World.COLORS.has(held) or held in ["jigger","shaker"]
	var desired = active() and pouring and can_pour
	var pose = Vector3(-0.39+aim_offset.x,0.45+aim_offset.y,-0.82) if desired else Vector3(0.32,-0.39,-0.60)
	held_root.position = held_root.position.lerp(pose,minf(1,delta*10))
	held_root.rotation.z = lerp_angle(held_root.rotation.z, -2.0 if desired else 0.0,minf(1,delta*10))
	if mixing: held_root.position.x += sin(elapsed*28)*0.025
	var from = held_root.to_global(Vector3(0,0.457 if World.COLORS.has(held) else 0.30,0))
	var velocity = -player.global_basis.z * 0.25 + Vector3.DOWN * 0.2
	var receivers = []
	var exclusions: Array[RID] = [player.get_rid()]
	for vessel in ["glass","jigger","shaker"]:
		var node = world.interactables[vessel]
		for child in node.get_children():
			if child is StaticBody3D: exclusions.append(child.get_rid())
		if vessel != held:
			var height = 0.26 if vessel == "glass" else (0.137 if vessel == "jigger" else 0.36)
			var radius = (0.108 if drink.glass_type == "coupe" else 0.079) if vessel == "glass" else (0.046 if vessel == "jigger" else 0.055)
			receivers.append({"id":vessel,"center":node.global_position+Vector3(0,height,0),"radius":radius})
	var collision = func(a,b):
		var query = PhysicsRayQueryParameters3D.create(a,b)
		query.exclude = exclusions
		return get_world_3d().direct_space_state.intersect_ray(query)
	landing = LiquidPhysics.trace(from,velocity,receivers,collision) if desired else {"container":"","position":from,"time":0.1}
	var emitting = desired and held_root.rotation.z < -1.8
	var before = drink.spilled
	if emitting:
		var amount = delta * 28.0
		if stock.has(held):
			amount = minf(amount,stock[held])
			stock[held] -= amount
			if landing.container == "": drink.spilled += amount
			else: drink.pour(held,amount,landing.container)
		else:
			amount = minf(amount,drink.volume(held))
			drink.decant(held,landing.container,amount)
		emitting = amount > 0
	career.waste += drink.spilled-before
	marker.visible = desired
	marker.global_position = landing.position + Vector3(0,0.003,0)
	marker.material_override.albedo_color = Color("66e6b5") if landing.container != "" else Color("ef754c")
	stream.flight_time = maxf(0.01,landing.time)
	stream.launch_velocity = velocity
	stream.update_flow(delta,emitting,from,landing.position,World.COLORS.get(held,Color("dec18b")))
	sound.flow(emitting)

func drop_glass() -> void:
	career.waste += drink.volume("glass")
	career.breakages += 1
	drink.liquid.glass = {}
	drink.ice.glass = false
	drink.garnish = "none"
	var body = RigidBody3D.new()
	add_child(body)
	body.add_to_group("loose_glass")
	body.global_position = held_root.global_position
	world.vessel(body,"glass",Vector3.ZERO)
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 0.08
	shape.height = 0.26
	collision.shape = shape
	body.add_child(collision)
	body.linear_velocity = -camera.global_basis.z * 1.7
	body.angular_velocity = Vector3(3,1,2)
	body.contact_monitor = true
	body.max_contacts_reported = 2
	body.body_entered.connect(func(_other):
		if not body.has_meta("broken"):
			body.set_meta("broken",true)
			sound.play("break")
			world.shatter(body.global_position)
			body.queue_free()
	)
	get_tree().create_timer(5).timeout.connect(func():
		if is_instance_valid(body): body.queue_free()
	)
	set_held("")
	note("Glass dropped. €2.50 damage plus wasted ingredients.")
