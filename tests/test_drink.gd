extends SceneTree

func _initialize() -> void:
	var script = load("res://scripts/drink.gd")
	if script == null:
		push_error("Drink implementation missing")
		quit(1)
		return
	var d = script.new()
	d.pour("gin", 60.0, "jigger")
	assert(is_equal_approx(d.volume("jigger"), 50.0), "Jigger must cap at 50 ml")
	assert(is_equal_approx(d.spilled, 10.0), "Excess must spill")
	d.transfer("jigger", "glass")
	d.transfer("jigger", "glass")
	assert(is_equal_approx(d.volume("glass"), 50.0), "Cannot transfer twice")
	d.pour("tonic", 150.0, "glass")
	d.ice["glass"] = true
	d.garnish = "lime"
	assert(d.quality(0) == 100, "Perfect G&T")
	d.pour("rum", 150.0, "glass")
	assert(d.quality(0) < 70, "Wrong ingredients must reduce quality")
	d.clear()
	d.pour("gin", -5.0, "glass")
	d.pour("gin", INF, "glass")
	assert(d.volume("glass") == 0.0)
	assert(d.quality(0) == 0)
	d.pour("rum", 60.0, "shaker")
	d.pour("lime", 25.0, "shaker")
	d.pour("syrup", 15.0, "shaker")
	d.ice["shaker"] = true
	d.method["shaker"] = "shake"
	d.glass_type = "coupe"
	d.garnish = "lime"
	d.transfer("shaker", "glass")
	assert(d.quality(3) == 100, "Shaken daiquiri survives straining")
	var career_script = load("res://scripts/career.gd")
	var c = career_script.new()
	c.start(true)
	c.tick(999.0)
	assert(c.time_left == 180.0, "Practice is untimed")
	c.serve(100)
	var xp = c.xp
	c.serve(100)
	assert(c.xp == xp, "Duplicate serving blocked")
	c.start(false)
	c.paused = true
	c.tick(10.0)
	assert(c.time_left == 180.0, "Pause freezes shift")
	c.paused = false
	c.tick(181.0)
	assert(c.state == "results")
	print("PASS: drink volumes, overflow, transfers, scores, practice, pause and duplicate serve")
	quit(0)
