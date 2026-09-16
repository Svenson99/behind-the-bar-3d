extends SceneTree

func _initialize() -> void:
	var c = load("res://scripts/career.gd").new()
	c.start(false)
	assert(c.customers.size() == 4)
	c.tick(20.0)
	assert(c.customers.filter(func(p): return p.state == "waiting").size() >= 2)
	var other_patience = c.customers[1].patience
	c.serve_customer(0, 100)
	assert(c.state == "playing", "Serving must not stop other customers")
	var xp = c.xp
	c.serve_customer(0, 100)
	assert(c.xp == xp, "Same patron cannot be served twice")
	c.tick(1.0)
	assert(c.customers[1].patience < other_patience)
	c.paused = true
	var remaining = c.time_left
	c.tick(100.0)
	assert(c.time_left == remaining)
	c.paused = false
	c.tick(200.0)
	assert(c.state == "results")
	assert(c.lost > 0, "Ignored customers leave")
	c.start(true)
	c.tick(500.0)
	assert(c.lost == 0)
	c.serve_customer(0, 100)
	assert(c.xp == xp, "Practice cannot farm career unlocks")
	var flow = load("res://scripts/liquid_physics.gd")
	var receiver = [{"id":"glass", "center":Vector3(0,1,0), "radius":0.08}]
	var hit = flow.trace(Vector3(0,1.5,0), Vector3.ZERO, receiver)
	assert(hit.container == "glass")
	var miss = flow.trace(Vector3(0.15,1.5,0), Vector3.ZERO, receiver)
	assert(miss.container == "", "Pouring next to a glass must miss")
	assert(miss.position.y < 0.01)
	var d = load("res://scripts/drink.gd").new()
	d.pour("gin", 40, "jigger")
	d.decant("jigger", "glass", 10)
	assert(is_equal_approx(d.volume("jigger"),30))
	assert(is_equal_approx(d.volume("glass"),10))
	d.decant("jigger", "", 10)
	assert(is_equal_approx(d.spilled,10))
	print("PASS: concurrent service, expiry, pause, practice, missed pours and gradual decanting")
	quit(0)
