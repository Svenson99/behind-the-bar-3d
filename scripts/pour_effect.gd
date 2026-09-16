extends Node3D

# Lightweight ballistic visual effect; recipe volumes remain in Drink.
const GRAVITY = Vector3(0, -9.81, 0)
const SEGMENTS = 24
const DROP_COUNT = 48
var segments: Array[MeshInstance3D] = []
var drops: Array[Dictionary] = []
var material := StandardMaterial3D.new()
var clock := 0.0
var flowing := false
var emission := 0.0
var cursor := 0
var last_origin := Vector3.ZERO

static func trajectory(origin: Vector3, velocity: Vector3, time: float) -> Vector3:
	return origin + velocity * time + GRAVITY * time * time * 0.5

func _ready() -> void:
	material.roughness = 0.16
	material.metallic_specular = 0.8
	var tube := CylinderMesh.new()
	tube.top_radius = 0.005
	tube.bottom_radius = 0.005
	tube.height = 1.0
	tube.radial_segments = 8
	for i in range(SEGMENTS):
		segments.append(make_mesh(tube))
	var bead := SphereMesh.new()
	bead.radius = 0.007
	bead.height = 0.014
	bead.radial_segments = 8
	bead.rings = 4
	for i in range(DROP_COUNT):
		drops.append({"mesh": make_mesh(bead), "velocity": Vector3.ZERO, "life": 0.0})

func make_mesh(shape: Mesh) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.mesh = shape
	instance.material_override = material
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visible = false
	add_child(instance)
	return instance

func drop(at: Vector3, velocity: Vector3, lifetime: float) -> void:
	var particle = drops[cursor]
	cursor = (cursor + 1) % DROP_COUNT
	particle.mesh.position = at
	particle.mesh.visible = true
	particle.velocity = velocity
	particle.life = lifetime

func update_flow(delta: float, enabled: bool, origin: Vector3, impact: Vector3, color: Color) -> void:
	clock += delta
	material.albedo_color = color.lightened(0.18)
	for particle in drops:
		if particle.life <= 0.0:
			continue
		particle.life -= delta
		particle.mesh.position += particle.velocity * delta + GRAVITY * delta * delta * 0.5
		particle.velocity += GRAVITY * delta
		particle.mesh.scale = Vector3.ONE * clampf(particle.life * 8.0, 0.0, 1.0)
		particle.mesh.visible = particle.life > 0.0
	for segment in segments:
		segment.visible = enabled
	if not enabled:
		if flowing:
			for i in range(4):
				drop(last_origin + Vector3(0, -i * 0.025, 0), Vector3.DOWN * 0.3, 0.22)
		flowing = false
		emission = 0.0
		return
	flowing = true
	last_origin = origin
	# Aim assistance stays consistent with the existing crosshair interaction.
	# Solve launch velocity; every point then follows gravity rather than a line.
	var flight := clampf(origin.distance_to(impact) / 2.8, 0.16, 0.65)
	var velocity := (impact - origin - GRAVITY * flight * flight * 0.5) / flight
	for i in range(SEGMENTS):
		var t0 := flight * float(i) / SEGMENTS
		var t1 := flight * float(i + 1) / SEGMENTS
		var a := trajectory(origin, velocity, t0)
		var b := trajectory(origin, velocity, t1)
		var direction := b - a
		var segment := segments[i]
		segment.position = (a + b) * 0.5
		segment.quaternion = Quaternion(Vector3.UP, direction.normalized())
		var width := (1.0 - float(i) / SEGMENTS * 0.35) * (1.0 + sin(clock * 27.0 - i * 0.8) * 0.12)
		segment.scale = Vector3(width, direction.length() * 1.04, width)
	emission += delta
	while emission >= 0.045:
		emission -= 0.045
		var angle := clock * 43.0 + cursor * 2.4
		drop(impact, Vector3(cos(angle) * 0.15, 0.3, sin(angle) * 0.15), 0.065)
		var t := flight * 0.78
		drop(trajectory(origin, velocity, t), velocity + GRAVITY * t, flight - t)
