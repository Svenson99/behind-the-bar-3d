extends Node3D

const COLORS = {"gin":Color("8dbbad"),"tonic":Color("b9ceab"),"rum":Color("ad753c"),"cola":Color("523727"),"vodka":Color("9fb9cb"),"orange":Color("e6a444"),"lime":Color("9dbf58"),"syrup":Color("c9a86f"),"vermouth":Color("8e493c")}
var interactables = {}
var liquid_mesh: MeshInstance3D
var ice_mesh: Node3D
var garnish_mesh: MeshInstance3D
var customers: Array[Node3D] = []
var customer_labels: Array[Label3D] = []
var venue_panels: Array[MeshInstance3D] = []
var venue_sign: Label3D
var room_environment: Environment
var materials = {}
var shards: Array[Node3D] = []
var ceiling: MeshInstance3D
var venue_details: Array[Node3D] = []

func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var key = str(color)+str(metal)
	if materials.has(key): return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.22 if metal > 0.0 else 0.58
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 0.08
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	materials[key] = m
	return m

func surface(mesh: MeshInstance3D, kind: String) -> void:
	var key = "surface_"+kind
	if not materials.has(key):
		var m = StandardMaterial3D.new()
		var noise = FastNoiseLite.new()
		noise.seed = 42
		noise.frequency = 0.035 if kind == "wood" else 0.015
		noise.fractal_octaves = 4
		var texture = NoiseTexture2D.new()
		texture.width = 512
		texture.height = 512
		texture.seamless = true
		texture.noise = noise
		var gradient = Gradient.new()
		gradient.set_color(0,Color("24150f") if kind == "wood" else Color("252d31"))
		gradient.set_color(1,Color("98643d") if kind == "wood" else Color("86908b"))
		texture.color_ramp = gradient
		m.albedo_texture = texture
		m.uv1_triplanar = true
		m.uv1_scale = Vector3(0.6,12,12) if kind == "wood" else Vector3(1.5,1.5,1.5)
		m.roughness = 0.3 if kind == "wood" else 0.2
		materials[key] = m
	mesh.material_override = materials[key]

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, solid: bool = false, tag: String = "") -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material(color)
	parent.add_child(mesh)
	mesh.position = at
	if solid:
		var body = StaticBody3D.new()
		mesh.add_child(body)
		var collision = CollisionShape3D.new()
		var bounds = BoxShape3D.new()
		bounds.size = size
		collision.shape = bounds
		body.add_child(collision)
		if not tag.is_empty():
			body.set_meta("item", tag)
	return mesh

func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, color: Color, top: float = -1.0, metallic: float = 0.0) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.bottom_radius = radius
	shape.top_radius = radius if top < 0.0 else top
	shape.height = height
	shape.radial_segments = 20
	mesh.mesh = shape
	mesh.material_override = material(color, metallic)
	parent.add_child(mesh)
	mesh.position = at
	return mesh

func label(parent: Node3D, text: String, at: Vector3, size: int = 28) -> Label3D:
	var l = Label3D.new()
	l.text = text
	l.font_size = size
	l.pixel_size = 0.003
	l.modulate = Color("f4ddab")
	l.outline_modulate = Color("1a2d26")
	l.outline_size = 8
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(l)
	l.position = at
	return l

func hitbox(parent: Node3D, size: Vector3, tag: String) -> void:
	var body = StaticBody3D.new()
	parent.add_child(body)
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position.y = size.y / 2.0
	body.add_child(collision)
	body.set_meta("item", tag)
	interactables[tag] = parent

func bottle(parent: Node3D, ingredient: String, at: Vector3, interactive: bool = false) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = at
	var color = COLORS[ingredient]
	cylinder(root, Vector3(0,0.14,0), 0.062, 0.28, color)
	cylinder(root, Vector3(0,0.31,0), 0.062, 0.07, color, 0.025)
	cylinder(root, Vector3(0,0.39,0), 0.025, 0.10, color)
	cylinder(root, Vector3(0,0.445,0), 0.028, 0.024, Color("c7ab74"), -1.0, 0.6)
	cylinder(root, Vector3(0,0.15,0), 0.063, 0.13, Color("e9dfc4"))
	var writing = label(root, ingredient.to_upper(), Vector3(0,0.16,0.066), 17)
	writing.pixel_size = 0.001
	if interactive:
		hitbox(root, Vector3(0.15,0.49,0.15), ingredient)
		label(root, ingredient.to_upper(), Vector3(0,0.57,0), 19)
	return root

func vessel(parent: Node3D, kind: String, at: Vector3, interactive: bool = false) -> Node3D:
	var root = Node3D.new()
	parent.add_child(root)
	root.position = at
	if kind == "glass":
		var bowl = cylinder(root, Vector3(0,0.13,0), 0.078, 0.26, Color(0.80,0.94,0.9,0.18), 0.084)
		bowl.name = "Bowl"
		cylinder(root, Vector3(0,0.015,0), 0.078, 0.03, Color("b3cfc2"))
		var stem = cylinder(root, Vector3(0,0.085,0), 0.01, 0.14, Color("c4d9c8"))
		stem.name = "Stem"
		stem.visible = false
		var ring = MeshInstance3D.new()
		ring.name = "Rim"
		var torus = TorusMesh.new()
		torus.inner_radius = 0.078
		torus.outer_radius = 0.088
		ring.mesh = torus
		ring.material_override = material(Color("dce8d7"), 0.15)
		root.add_child(ring)
		ring.position.y = 0.26
	elif kind == "jigger":
		cylinder(root, Vector3(0,0.037,0), 0.04, 0.075, Color("b2bab0"), 0.02, 0.85)
		cylinder(root, Vector3(0,0.105,0), 0.02, 0.065, Color("b2bab0"), 0.05, 0.85)
	else:
		cylinder(root, Vector3(0,0.16,0), 0.075, 0.32, Color("a5b0a8"), 0.058, 0.8)
		cylinder(root, Vector3(0,0.34,0), 0.058, 0.04, Color("c8cfc4"), 0.04, 0.8)
	if interactive:
		hitbox(root, Vector3(0.22,0.4,0.22), kind)
		label(root, kind.to_upper(), Vector3(0,0.48,0), 21)
	return root

func glass_shape(root: Node3D, kind: String) -> void:
	var bowl = root.get_node("Bowl")
	var coupe = kind == "coupe"
	bowl.mesh.bottom_radius = 0.018 if coupe else 0.078
	bowl.mesh.top_radius = 0.112 if coupe else 0.084
	bowl.mesh.height = 0.12 if coupe else 0.26
	bowl.position.y = 0.20 if coupe else 0.13
	root.get_node("Stem").visible = coupe
	root.get_node("Rim").scale = Vector3(1.35,1,1.35) if coupe else Vector3.ONE

func build() -> void:
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1c3029")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d7dfc9")
	env.ambient_light_energy = 0.38
	room_environment = env
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_color = Color("ffe0ad")
	sun.light_energy = 0.6
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 18
	add_child(sun)
	surface(box(self,Vector3(0,-0.1,-1),Vector3(12,0.2,12),Color("574433"),true),"wood")
	for i in range(25):
		box(self,Vector3(-6+i*0.5,0.004,-1),Vector3(0.014,0.005,12),Color("302a24"))
	venue_panels.append(box(self,Vector3(0,1.8,-6.8),Vector3(12,3.6,0.2),Color("234737"),true))
	box(self,Vector3(-5.9,1.8,-1),Vector3(0.2,3.6,12),Color("294638"),true)
	box(self,Vector3(5.9,1.8,-1),Vector3(0.2,3.6,12),Color("294638"),true)
	box(self,Vector3(0,1.8,3.8),Vector3(12,3.6,0.2),Color("193b2c"),true)
	ceiling = box(self,Vector3(0,3.65,-1),Vector3(12,0.1,12),Color("26362c"))
	# Counter: the player starts on the bartender side (+Z).
	box(self,Vector3(0,0.51,0),Vector3(7.6,1.02,0.75),Color("263e30"),true)
	surface(box(self,Vector3(0,1.06,0),Vector3(7.9,0.1,0.95),Color("a37649"),true),"wood")
	for x in [-3.1,-1.55,0.0,1.55,3.1]:
		venue_panels.append(box(self,Vector3(x,0.49,-0.39),Vector3(1.4,0.75,0.018),Color("39513a")))
	box(self,Vector3(0.7,1.116,0.15),Vector3(2.0,0.012,0.57),Color("18382c"))
	for i in range(9):
		bottle(self, COLORS.keys()[i], Vector3(-3.1+i*0.31,1.12,0.15), true)
	var glass = vessel(self,"glass",Vector3(0.4,1.12,0.15),true)
	vessel(self,"jigger",Vector3(0.95,1.12,0.15),true)
	vessel(self,"shaker",Vector3(1.5,1.12,0.15),true)
	liquid_mesh = cylinder(glass,Vector3(0,0.03,0),0.074,0.005,Color("dfbc73"))
	liquid_mesh.material_override = liquid_mesh.material_override.duplicate()
	liquid_mesh.material_override.roughness = 0.12
	ice_mesh = Node3D.new()
	glass.add_child(ice_mesh)
	for i in range(3):
		var cube = box(ice_mesh,Vector3((i-1)*0.025,0.08+i*0.045,0),Vector3(0.055,0.055,0.055),Color(0.8,0.96,1,0.75))
		cube.rotation_degrees.y = i*35
	garnish_mesh = cylinder(glass,Vector3(0.07,0.25,0),0.04,0.012,Color("b0ce61"))
	garnish_mesh.material_override = garnish_mesh.material_override.duplicate()
	garnish_mesh.rotation_degrees.z = 75
	box(self,Vector3(2.18,1.19,0.1),Vector3(0.42,0.16,0.32),Color("889d96"),true,"ice")
	label(self,"ICE",Vector3(2.18,1.53,0.1),22)
	for i in range(5):
		box(self,Vector3(2.02+(i%3)*0.12,1.3,0.03+(i/3)*0.1),Vector3(0.07,0.06,0.07),Color("d4eddf"))
	box(self,Vector3(2.8,1.15,0.1),Vector3(0.42,0.07,0.35),Color("ad8b55"),true,"garnish")
	label(self,"GARNISH",Vector3(2.8,1.53,0.1),22)
	for i in range(4):
		cylinder(self,Vector3(2.7+i*0.07,1.21,0.1),0.043,0.015,Color("adcd5a"))
	# Back bar, lamps and individually modelled bottles.
	for y in [1.05,1.85,2.6]:
		box(self,Vector3(0,y,3.5),Vector3(7.8,0.08,0.5),Color("a17645"))
		for i in range(19):
			bottle(self,COLORS.keys()[i%9],Vector3(-3.5+i*0.38,y+0.05,3.5))
	for x in [-3.0,0.0,3.0]:
		cylinder(self,Vector3(x,3.2,0),0.015,0.7,Color("342c20"))
		cylinder(self,Vector3(x,2.86,0),0.32,0.2,Color("c39650"),0.08,0.65)
		var lamp = OmniLight3D.new()
		lamp.position = Vector3(x,2.65,0)
		lamp.light_color = Color("ffd59a")
		lamp.light_energy = 1.8
		lamp.omni_range = 4.5
		add_child(lamp)
	venue_sign = label(self,"THE COPPER FOX",Vector3(0,2.7,-6.65),95)
	label(self,"NEIGHBOURHOOD PUB • EST. 1986",Vector3(0,2.25,-6.65),25)
	# Seating gives the world depth beyond the bar.
	for x in [-3.6,3.6]:
		for z in [-3.2,-5.2]:
			cylinder(self,Vector3(x,0.77,z),0.65,0.09,Color("9a6e40"))
			cylinder(self,Vector3(x,0.39,z),0.06,0.76,Color("26382b"))
			for dx in [-0.85,0.85]:
				cylinder(self,Vector3(x+dx,0.52,z),0.23,0.1,Color("643b2e"))
				cylinder(self,Vector3(x+dx,0.25,z),0.045,0.5,Color("34372b"))
	build_customers()
	decorate()
	build_venues()
	set_venue(0)

func oval(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radial_segments = 20
	mesh.rings = 12
	instance.mesh = mesh
	instance.material_override = material(color)
	parent.add_child(instance)
	instance.position = at
	instance.scale = size
	return instance

func limb(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var node = cylinder(parent,(a+b)*0.5,radius,a.distance_to(b),color,radius*0.86)
	node.quaternion = Quaternion(Vector3.UP,(b-a).normalized())
	oval(parent,a,Vector3.ONE*radius*1.8,color)
	oval(parent,b,Vector3.ONE*radius*1.7,color)

func build_customers() -> void:
	for i in range(4):
		var x = -2.7+i*1.8
		cylinder(self,Vector3(x,0.78,-0.92),0.25,0.10,Color("593b2d"))
		cylinder(self,Vector3(x,0.4,-0.92),0.045,0.75,Color("8e7859"),-1,0.8)
		cylinder(self,Vector3(x,0.025,-0.92),0.27,0.05,Color("786855"),-1,0.8)
		var person = Node3D.new()
		add_child(person)
		person.position = Vector3(x,0,-0.95)
		customers.append(person)
		var skin = [Color("c79876"),Color("8d6147"),Color("dcb291"),Color("ab795d")][i]
		var shirt = [Color("384e5b"),Color("7a3b39"),Color("c7b9a0"),Color("354a3a")][i]
		oval(person,Vector3(0,1.13,0),Vector3(0.43,0.55,0.26),shirt)
		cylinder(person,Vector3(0,1.44,0),0.065,0.12,skin)
		oval(person,Vector3(0,1.62,0),Vector3(0.26,0.34,0.26),skin)
		oval(person,Vector3(0,1.74,-0.015),Vector3(0.27,0.15,0.26),Color("38291f") if i%2==0 else Color("8b693d"))
		oval(person,Vector3(0,1.61,0.13),Vector3(0.038,0.06,0.06),skin)
		for side in [-1,1]:
			oval(person,Vector3(side*0.053,1.66,0.117),Vector3(0.027,0.016,0.018),Color("ebe3cf"))
			oval(person,Vector3(side*0.053,1.66,0.127),Vector3(0.011,0.012,0.01),Color("2b2521"))
			limb(person,Vector3(side*0.19,1.34,0),Vector3(side*0.27,1.05,0.12),0.07,shirt)
			limb(person,Vector3(side*0.27,1.05,0.12),Vector3(side*0.18,1.13,0.4),0.048,skin)
			oval(person,Vector3(side*0.18,1.13,0.4),Vector3(0.075,0.045,0.12),skin)
			limb(person,Vector3(side*0.115,0.88,0),Vector3(side*0.14,0.77,0.33),0.085,Color("292c32"))
			limb(person,Vector3(side*0.14,0.77,0.33),Vector3(side*0.14,0.35,0.29),0.065,Color("292c32"))
			oval(person,Vector3(side*0.14,0.32,0.35),Vector3(0.13,0.10,0.24),Color("302923"))
		hitbox(person,Vector3(0.72,1.85,0.6),"customer_%d" % i)
		var title = label(person,"Seat %d" % [i+1],Vector3(0,2.04,0),19)
		title.pixel_size = 0.002
		customer_labels.append(title)

func update_customers(career, time: float) -> void:
	for body in get_tree().get_nodes_in_group("loose_glass"):
		body.freeze = career.paused
	for i in range(customers.size()):
		var person = customers[i]
		person.visible = not career.customers.is_empty() and career.state != "menu"
		if not person.visible: continue
		var p = career.customers[i]
		var away = clampf(p.timer/7.0,0,1) if p.state == "arriving" else (1-clampf(p.timer/4.0,0,1) if p.state == "leaving" else 0.0)
		person.position.z = -0.95-away*4.3
		person.position.y = sin(time*1.5+i)*0.006
		person.rotation.y = PI if p.state == "leaving" else 0.0
		customer_labels[i].text = "%d • %s\n%s" % [i+1,p.name,"%ds" % int(p.patience) if p.state == "waiting" else p.state.capitalize()]
		customer_labels[i].modulate = Color("ff9066") if p.patience < 25 else Color("eedac0")

func set_venue(index: int) -> void:
	venue_sign.text = preload("res://scripts/career.gd").VENUES[index].to_upper()
	var colors = [Color("294638"),Color("442735"),Color("334957")]
	for panel in venue_panels: panel.material_override = material(colors[index])
	room_environment.ambient_light_color = [Color("d7c9b3"),Color("c6b6de"),Color("c3dceb")][index]
	room_environment.ambient_light_energy = [0.38,0.30,0.60][index]
	room_environment.background_color = [Color("1c3029"),Color("201a2d"),Color("596e89")][index]
	ceiling.visible = index != 2
	venue_panels[0].visible = index != 2
	for i in range(venue_details.size()): venue_details[i].visible = i == index

func build_venues() -> void:
	for i in range(3):
		var details = Node3D.new()
		add_child(details)
		venue_details.append(details)
	# Copper Fox: framed house artwork and draught taps.
	for x in [-3.8,3.8]:
		box(venue_details[0],Vector3(x,2.1,-6.58),Vector3(1.05,0.85,0.07),Color("98703e"))
		box(venue_details[0],Vector3(x,2.1,-6.52),Vector3(0.91,0.71,0.025),Color("293e32"))
		label(venue_details[0],"COPPER\n& CRAFT",Vector3(x,2.1,-6.49),30)
	for x in [-3.55,-3.35]:
		cylinder(venue_details[0],Vector3(x,1.32,0),0.025,0.4,Color("c09450"),-1,0.85)
		box(venue_details[0],Vector3(x,1.51,0.06),Vector3(0.05,0.05,0.17),Color("c09450"))
	# Lounge: velvet dividers, stone table tops and a brass chandelier.
	for x in [-4.2,4.2]:
		for j in range(14):
			cylinder(venue_details[1],Vector3(x-0.65+j*0.1,2.15,-6.55),0.055,2.6,Color("582939"))
	for j in range(8):
		var angle = j*TAU/8
		var at = Vector3(cos(angle)*0.8,2.6,-3.4+sin(angle)*0.8)
		cylinder(venue_details[1],at,0.06,0.30,Color("e5c593"),-1,0.6)
		limb(venue_details[1],Vector3(0,2.9,-3.4),at,0.015,Color("b09555"))
	# Terrace: open ceiling, distant skyline, balcony and greenery.
	for i in range(21):
		var height = 2.0 + fmod(i*1.713,5.5)
		var x = -15+i*1.5
		box(venue_details[2],Vector3(x,height/2-1,-12-fmod(i*2.3,6)),Vector3(1.15,height,1.2),Color("344353"))
		for row in range(int(height*2)):
			for col in range(3):
				if (row+col+i)%3 == 0: continue
				var window = box(venue_details[2],Vector3(x-0.35+col*0.35,row*0.45-0.5,-11.38-fmod(i*2.3,6)),Vector3(0.14,0.19,0.02),Color("d8bd7d"))
				window.material_override = material(Color("d8bd7d")).duplicate()
				window.material_override.emission_enabled = true
				window.material_override.emission = Color("ae8b46")
	box(venue_details[2],Vector3(0,1.1,-6.5),Vector3(11.6,0.04,0.04),Color("8e9eaa"))
	for x in [-5,-3,-1,1,3,5]:
		box(venue_details[2],Vector3(x,0.55,-6.5),Vector3(0.03,1.1,0.03),Color("8e9eaa"))
	for x in [-5.4,5.4]:
		cylinder(venue_details[2],Vector3(x,0.3,-5.7),0.3,0.6,Color("594737"),0.38)
		for j in range(8):
			limb(venue_details[2],Vector3(x,0.4,-5.7),Vector3(x+sin(j)*0.4,1.2+fmod(j*0.3,0.7),-5.7+cos(j)*0.4),0.045,Color("4b6845"))

func decorate() -> void:
	# Millwork, brass rails, upholstered booths, sconces and window recesses.
	for x in [-5.5,-3.5,-1.5,1.5,3.5,5.5]:
		surface(box(self,Vector3(x,1.1,-6.62),Vector3(0.08,2.2,0.07),Color("8b633a")),"wood")
	box(self,Vector3(0,0.23,-0.62),Vector3(7.5,0.04,0.04),Color("b19057"))
	for x in [-4.5,4.5]:
		box(self,Vector3(x,0.55,-5.8),Vector3(1.8,0.3,0.8),Color("523632"))
		box(self,Vector3(x,1,-6.2),Vector3(1.8,0.9,0.16),Color("523632"))
		for z in [-2.5,-4.5]:
			var window = box(self,Vector3(signf(x)*5.77,2.15,z),Vector3(0.02,1.4,1.35),Color("426277"))
			window.material_override = window.material_override.duplicate()
			window.material_override.emission_enabled = true
			window.material_override.emission = Color("2b4659")
			box(self,Vector3(signf(x)*5.74,2.15,z),Vector3(0.05,1.45,0.04),Color("1d2528"))
			box(self,Vector3(signf(x)*5.74,2.15,z),Vector3(0.05,0.04,1.4),Color("1d2528"))
	for x in [-2.2,2.2]:
		var lamp = OmniLight3D.new()
		lamp.position = Vector3(x,2.1,-5.9)
		lamp.light_color = Color("ffbc7a")
		lamp.light_energy = 1.4
		lamp.omni_range = 3.0
		add_child(lamp)
		cylinder(self,Vector3(x,2.1,-6.4),0.13,0.3,Color("eac58c"))

func shatter(at: Vector3) -> void:
	while shards.size() > 48:
		var old = shards.pop_front()
		if is_instance_valid(old): old.queue_free()
	for i in range(10):
		var body = RigidBody3D.new()
		add_child(body)
		body.add_to_group("loose_glass")
		body.position = at
		box(body,Vector3.ZERO,Vector3(0.025,0.008,0.035),Color("bbd6d8"))
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.025,0.008,0.035)
		collision.shape = shape
		body.add_child(collision)
		body.linear_velocity = Vector3(sin(i*2.4),0.7,cos(i*2.4))*0.8
		body.angular_velocity = Vector3(i,3,1)
		shards.append(body)
		get_tree().create_timer(4).timeout.connect(func():
			if is_instance_valid(body): body.queue_free()
		)

func update_drink(drink) -> void:
	glass_shape(interactables["glass"],drink.glass_type)
	var coupe = drink.glass_type == "coupe"
	var height = maxf(0.005, drink.volume("glass") / (150.0 if coupe else 350.0) * (0.10 if coupe else 0.22))
	liquid_mesh.scale.y = height / 0.005
	liquid_mesh.scale.x = 1.1 if coupe else 1.0
	liquid_mesh.scale.z = 1.1 if coupe else 1.0
	liquid_mesh.position.y = (0.145 if coupe else 0.025) + height / 2.0
	liquid_mesh.visible = drink.volume("glass") > 0.0
	var color = Color("dfc998")
	if drink.liquid.glass.has("cola"):
		color = Color("512d1b")
	elif drink.liquid.glass.has("orange"):
		color = Color("e7ab40")
	liquid_mesh.material_override.albedo_color = color
	ice_mesh.visible = drink.ice.glass
	garnish_mesh.visible = drink.garnish != "none"
	garnish_mesh.material_override.albedo_color = Color("f0a236") if drink.garnish == "orange" else Color("9eb65b")
