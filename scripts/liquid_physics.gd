extends RefCounted

const GRAVITY = Vector3(0, -9.81, 0)
const STEP = 0.025

static func point(origin: Vector3, velocity: Vector3, t: float) -> Vector3:
	return origin + velocity * t + GRAVITY * t * t * 0.5

# Receivers are circular openings, not auto-targeted endpoints.
static func trace(origin: Vector3, velocity: Vector3, receivers: Array, collision: Callable = Callable()) -> Dictionary:
	var previous = origin
	for i in range(1, 61):
		var t = i * STEP
		var current = point(origin, velocity, t)
		var fraction = 2.0
		var container = ""
		for receiver in receivers:
			var center: Vector3 = receiver.center
			if previous.y >= center.y and current.y < center.y:
				var f = (previous.y - center.y) / (previous.y - current.y)
				var cross = previous.lerp(current, f)
				if Vector2(cross.x-center.x, cross.z-center.z).length() <= receiver.radius and f < fraction:
					fraction = f
					container = receiver.id
		if collision.is_valid():
			var hit = collision.call(previous, current)
			if not hit.is_empty():
				var f = previous.distance_to(hit.position) / maxf(previous.distance_to(current),0.00001)
				if f < fraction:
					fraction = f
					container = ""
		if current.y <= 0 and previous.y > 0:
			var f = previous.y / (previous.y-current.y)
			if f < fraction:
				fraction = f
				container = ""
		if fraction <= 1:
			return {"container":container,"position":previous.lerp(current,fraction),"time":t-STEP+STEP*fraction}
		previous = current
	return {"container":"","position":previous,"time":1.5}
