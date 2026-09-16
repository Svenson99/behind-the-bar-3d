extends Node3D

const COLORS = {"gin":Color("8dbbad"),"tonic":Color("b9ceab"),"rum":Color("ad753c"),"cola":Color("523727"),"vodka":Color("9fb9cb"),"orange":Color("e6a444"),"lime":Color("9dbf58"),"syrup":Color("c9a86f"),"vermouth":Color("8e493c")}
var interactables = {}
var liquid_mesh: MeshInstance3D
var ice_mesh: Node3D
var garnish_mesh: MeshInstance3D

func material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metal
	m.roughness = 0.35 if metal > 0.0 else 0.75
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

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
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55,-25,0)
	sun.light_color = Color("ffe0ad")
	sun.light_energy = 1.1
	add_child(sun)
	box(self,Vector3(0,-0.1,-1),Vector3(12,0.2,12),Color("574433"),true)
	for i in range(25):
		box(self,Vector3(-6+i*0.5,0.004,-1),Vector3(0.014,0.005,12),Color("302a24"))
	box(self,Vector3(0,1.8,-6.8),Vector3(12,3.6,0.2),Color("234737"),true)
	box(self,Vector3(-5.9,1.8,-1),Vector3(0.2,3.6,12),Color("294638"),true)
	box(self,Vector3(5.9,1.8,-1),Vector3(0.2,3.6,12),Color("294638"),true)
	box(self,Vector3(0,1.8,3.8),Vector3(12,3.6,0.2),Color("193b2c"),true)
	box(self,Vector3(0,3.65,-1),Vector3(12,0.1,12),Color("26362c"))
	# Counter: the player starts on the bartender side (+Z).
	box(self,Vector3(0,0.51,0),Vector3(7.6,1.02,0.75),Color("263e30"),true)
	box(self,Vector3(0,1.06,0),Vector3(7.9,0.1,0.95),Color("a37649"),true)
	for x in [-3.1,-1.55,0.0,1.55,3.1]:
		box(self,Vector3(x,0.49,-0.39),Vector3(1.4,0.75,0.018),Color("39513a"))
	box(self,Vector3(0.7,1.116,0.15),Vector3(2.0,0.012,0.57),Color("18382c"))
	for i in range(9):
		bottle(self, COLORS.keys()[i], Vector3(-3.1+i*0.31,1.12,0.15), true)
	var glass = vessel(self,"glass",Vector3(0.4,1.12,0.15),true)
	vessel(self,"jigger",Vector3(0.95,1.12,0.15),true)
	vessel(self,"shaker",Vector3(1.5,1.12,0.15),true)
	liquid_mesh = cylinder(glass,Vector3(0,0.03,0),0.074,0.005,Color("dfbc73"))
	ice_mesh = Node3D.new()
	glass.add_child(ice_mesh)
	for i in range(3):
		var cube = box(ice_mesh,Vector3((i-1)*0.025,0.08+i*0.045,0),Vector3(0.055,0.055,0.055),Color(0.8,0.96,1,0.75))
		cube.rotation_degrees.y = i*35
	garnish_mesh = cylinder(glass,Vector3(0.07,0.25,0),0.04,0.012,Color("b0ce61"))
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
	label(self,"THE COPPER FOX",Vector3(0,2.7,-6.65),95)
	label(self,"NEIGHBOURHOOD PUB • EST. 1986",Vector3(0,2.25,-6.65),25)
	# Seating gives the world depth beyond the bar.
	for x in [-3.6,3.6]:
		for z in [-3.2,-5.2]:
			cylinder(self,Vector3(x,0.77,z),0.65,0.09,Color("9a6e40"))
			cylinder(self,Vector3(x,0.39,z),0.06,0.76,Color("26382b"))
			for dx in [-0.85,0.85]:
				cylinder(self,Vector3(x+dx,0.52,z),0.23,0.1,Color("643b2e"))
				cylinder(self,Vector3(x+dx,0.25,z),0.045,0.5,Color("34372b"))
	var person = Node3D.new()
	add_child(person)
	person.position = Vector3(0.45,0,-1.05)
	box(person,Vector3(0,1.12,0),Vector3(0.48,0.65,0.26),Color("416154"))
	cylinder(person,Vector3(0,1.63,0),0.16,0.33,Color("c39972"))
	cylinder(person,Vector3(0,1.83,0),0.17,0.1,Color("493b2c"))
	for dx in [-0.11,0.11]:
		box(person,Vector3(dx,0.45,0),Vector3(0.17,0.9,0.2),Color("25332e"))
		box(person,Vector3(dx*2.4,1.12,0.12),Vector3(0.13,0.45,0.15),Color("c39972"))
		box(person,Vector3(dx*0.6,1.67,0.16),Vector3(0.035,0.025,0.015),Color("252b21"))
	hitbox(person,Vector3(0.75,1.95,0.5),"customer")
	label(person,"CUSTOMER • SERVE HERE",Vector3(0,2.1,0),26)

func update_drink(drink) -> void:
	glass_shape(interactables["glass"],drink.glass_type)
	var coupe = drink.glass_type == "coupe"
	var height = maxf(0.005, drink.volume("glass") / 350.0 * (0.10 if coupe else 0.22))
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
