extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var effect = load("res://scripts/pour_effect.gd").new()
	root.add_child(effect)
	var origin := Vector3(0, 1.5, 0)
	var impact := Vector3(0.6, 1.0, 0)
	effect.update_flow(0.05, true, origin, impact, Color("b87c32"))
	assert(effect.flowing)
	assert(effect.segments[0].visible)
	var first_direction = effect.segments[0].quaternion * Vector3.UP
	var last_direction = effect.segments[-1].quaternion * Vector3.UP
	assert(first_direction.y > last_direction.y, "Gravity must curve the stream downward")
	var end_segment = effect.segments[-1]
	var endpoint = end_segment.position + last_direction * end_segment.scale.y / 2.08
	assert(endpoint.distance_to(impact) < 0.001, "Stream must land at the liquid surface")
	var count = effect.get_child_count()
	for i in range(600):
		effect.update_flow(0.016, true, origin, impact, Color.WHITE)
	assert(effect.get_child_count() == count, "Long pours must not allocate more particles")
	assert(effect.drops.any(func(p): return p.life > 0), "Pour must emit droplets")
	effect.update_flow(0.016, false, origin, impact, Color.WHITE)
	assert(not effect.segments[0].visible)
	for i in range(60):
		effect.update_flow(0.016, false, origin, impact, Color.WHITE)
	assert(effect.drops.all(func(p): return not p.mesh.visible), "Drops must expire after release")
	print("PASS: gravity curvature, surface impact, bounded particles and release cleanup")
	quit(0)
