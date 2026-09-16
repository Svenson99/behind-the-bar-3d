extends CanvasLayer

const TouchButton = preload("res://scripts/touch_button.gd")

signal action(name: String)
signal pour_changed(value: bool)
var movement = Vector2.ZERO
var root: Control
var modal: PanelContainer
var order_label: Label
var stats_label: Label
var target_label: Label
var hint_label: Label
var readout: Label
var move_finger = -1
var tickets: Array[Button] = []
var backdrop: ColorRect
var title_label: Label

func style(color: Color, border: Color = Color("718369")) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

func text_at(text: String, at: Vector2, size: Vector2, font_size: int = 20) -> Label:
	var l = Label.new()
	l.text = text
	l.position = at
	l.size = size
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color("f2e5c8"))
	l.add_theme_color_override("font_shadow_color", Color("101b14"))
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l

func button(text: String, command: String, at: Vector2, size: Vector2) -> Button:
	var b = TouchButton.new()
	b.text = text
	b.position = at
	b.size = size
	b.add_theme_font_size_override("font_size", 19)
	b.add_theme_stylebox_override("normal", style(Color(0.07,0.19,0.14,0.94)))
	b.add_theme_stylebox_override("pressed", style(Color("a58a52")))
	b.add_theme_stylebox_override("hover", style(Color("365343")))
	b.pressed.connect(func(): action.emit(command))
	root.add_child(b)
	return b

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	title_label = text_at("BEHIND THE BAR",Vector2(26,12),Vector2(660,35),23)
	order_label = text_at("",Vector2(26,62),Vector2(410,180),21)
	stats_label = text_at("",Vector2(820,16),Vector2(300,36),21)
	target_label = text_at("",Vector2(440,400),Vector2(400,38),22)
	target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var cross = text_at("+",Vector2(624,339),Vector2(32,36),26)
	cross.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label = text_at("",Vector2(280,655),Vector2(720,54),18)
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	readout = text_at("",Vector2(485,545),Vector2(490,100),19)
	button("Pause", "pause", Vector2(1150,10),Vector2(108,52))
	button("Pick / use", "use",Vector2(1040,315),Vector2(214,60))
	var pour = button("HOLD TO POUR", "noop",Vector2(1040,385),Vector2(214,66))
	pour.button_down.connect(func(): pour_changed.emit(true))
	pour.button_up.connect(func(): pour_changed.emit(false))
	button("Shake / stir", "mix",Vector2(1040,465),Vector2(214,58))
	button("Glass type", "glass",Vector2(1040,533),Vector2(214,58))
	button("Set down", "drop",Vector2(1040,601),Vector2(214,58))
	button("Discard drink", "discard",Vector2(26,270),Vector2(175,50))
	button("Drop glass", "break",Vector2(26,335),Vector2(175,50))
	button("Recipes", "recipes",Vector2(26,400),Vector2(175,50))
	for i in range(4):
		var ticket = button("Seat %d" % [i+1], "seat_%d" % i, Vector2(435+i*151,110),Vector2(145,116))
		ticket.add_theme_font_size_override("font_size",16)
		tickets.append(ticket)
	var pad = Panel.new()
	pad.position = Vector2(36,460)
	pad.size = Vector2(190,190)
	pad.add_theme_stylebox_override("panel", style(Color(0.07,0.19,0.14,0.7)))
	root.add_child(pad)
	var pad_text = Label.new()
	pad_text.text = "↑\n←   MOVE   →\n↓"
	pad_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pad_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pad_text.size = pad.size
	pad_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(pad_text)
	pad.gui_input.connect(func(event):
		if event is InputEventScreenTouch:
			if event.pressed and move_finger == -1:
				move_finger = event.index
				movement = ((event.position-Vector2(95,95))/70.0).limit_length()
			elif not event.pressed and event.index == move_finger:
				move_finger = -1
				movement = Vector2.ZERO
		elif event is InputEventScreenDrag and event.index == move_finger:
			movement = ((event.position-Vector2(95,95))/70.0).limit_length()
		elif event is InputEventMouseButton:
			movement = ((event.position-Vector2(95,95))/70.0).limit_length() if event.pressed else Vector2.ZERO
		elif event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			movement = ((event.position-Vector2(95,95))/70.0).limit_length()
	)
	text_at("DRAG THE WORLD TO LOOK",Vector2(470,70),Vector2(440,30),15)
	backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.015,0.02,0.025,0.82)
	root.add_child(backdrop)
	backdrop.hide()
	modal = PanelContainer.new()
	modal.position = Vector2(250,36)
	modal.size = Vector2(780,648)
	modal.add_theme_stylebox_override("panel",style(Color(0.045,0.12,0.09,0.98),Color("a58a52")))
	root.add_child(modal)
	modal.hide()

func show_dialog(title: String, body: String, choices: Dictionary) -> void:
	for child in modal.get_children():
		modal.remove_child(child)
		child.queue_free()
	var column = VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	modal.add_child(column)
	var heading = Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size",34)
	column.add_child(heading)
	var description = Label.new()
	description.text = body
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_font_size_override("font_size",20)
	description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(description)
	for caption in choices:
		var command = choices[caption]
		var b = TouchButton.new()
		b.text = caption
		b.custom_minimum_size.y = 58
		b.add_theme_font_size_override("font_size",22)
		b.pressed.connect(func(): action.emit(command))
		column.add_child(b)
	modal.show()
	backdrop.show()
	movement = Vector2.ZERO
	move_finger = -1

func hide_dialog() -> void:
	modal.hide()
	backdrop.hide()

func update_tickets(customers: Array, selected: int) -> void:
	for i in range(tickets.size()):
		var p = customers[i]
		var state_text = "%ds left" % int(p.patience) if p.state == "waiting" else p.state.capitalize()
		tickets[i].text = "%s %d • %s\n%s\n%s" % ["▸" if selected == i else "",i+1,p.name,preload("res://scripts/drink.gd").RECIPES[p.recipe].name,state_text]
		tickets[i].modulate = Color("ffac83") if p.state == "waiting" and p.patience < 25 else Color.WHITE
