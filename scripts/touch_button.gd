extends Button

# Keep independent touch ownership so movement and pouring can overlap.
# Native Button continues to handle mouse and keyboard input.
var finger := -1
var original_tint := Color.WHITE

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not event.canceled:
		if finger == -1 and not disabled:
			finger = event.index
			original_tint = self_modulate
			self_modulate = original_tint * Color(0.8, 0.8, 0.8)
			button_down.emit()
			accept_event()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.index == finger and not event.pressed:
		var local_position = get_global_transform_with_canvas().affine_inverse() * event.position
		var activate = not event.canceled and not disabled and is_visible_in_tree()
		activate = activate and Rect2(Vector2.ZERO, size).has_point(local_position)
		get_viewport().set_input_as_handled()
		release_touch(activate)

func release_touch(activate: bool = false) -> void:
	if finger == -1:
		return
	finger = -1
	self_modulate = original_tint
	button_up.emit()
	if activate:
		pressed.emit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_EXIT_TREE:
		release_touch()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		release_touch()
