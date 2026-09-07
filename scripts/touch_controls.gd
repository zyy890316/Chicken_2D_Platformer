extends CanvasLayer

## On-screen left / right / jump for phones. Keyboard still works on desktop.
## Digital pad, not a stick: this climb is binary left/right, and kids
## overshoot analog sticks.

var _pad: Control
var _move_left: Control
var _move_right: Control


func _ready() -> void:
	layer = 20
	_pad = _build()
	_pad.visible = _should_show()


func _process(_delta: float) -> void:
	if _pad == null or not _pad.visible:
		return
	var playing := not GameState.is_won
	_move_left.visible = playing
	_move_right.visible = playing


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_pad.visible = true


func _should_show() -> bool:
	return OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()


func _build() -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left_tex := _circle_button(Color(0.16, 0.16, 0.16, 0.55), "left")
	var right_tex := _circle_button(Color(0.16, 0.16, 0.16, 0.55), "right")
	var jump_tex := _circle_button(Color(0.14, 0.45, 0.28, 0.65), "jump")

	_move_left = _add_button(root, left_tex, "move_left", true, 28.0, 148.0)
	_move_right = _add_button(root, right_tex, "move_right", true, 188.0, 148.0)
	var jump_slot := _add_button(root, jump_tex, "jump", false, 28.0, 168.0)
	_add_caption(jump_slot, "JUMP")
	return root


func _add_button(
	root: Control,
	texture: Texture2D,
	action: String,
	from_left: bool,
	edge_margin: float,
	size: float
) -> Control:
	var slot := Control.new()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.anchor_top = 1.0
	slot.anchor_bottom = 1.0
	if from_left:
		slot.anchor_left = 0.0
		slot.anchor_right = 0.0
		slot.offset_left = edge_margin
		slot.offset_right = edge_margin + size
	else:
		slot.anchor_left = 1.0
		slot.anchor_right = 1.0
		slot.offset_right = -edge_margin
		slot.offset_left = -edge_margin - size
	slot.offset_bottom = -36.0
	slot.offset_top = -36.0 - size

	var btn := TouchScreenButton.new()
	btn.texture_normal = texture
	btn.action = action
	btn.passby_press = true
	var tex_size := texture.get_size()
	btn.scale = Vector2(size / tex_size.x, size / tex_size.y)
	slot.add_child(btn)
	root.add_child(slot)
	return slot


func _add_caption(slot: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	label.offset_left = -40
	label.offset_right = 40
	label.offset_top = -22
	label.offset_bottom = 0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(label)


func _circle_button(fill: Color, kind: String) -> ImageTexture:
	var size := 192
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.5 - 6.0
	for y in size:
		for x in size:
			var point := Vector2(x + 0.5, y + 0.5)
			var dist := point.distance_to(center)
			if dist > radius:
				continue
			if dist >= radius - 7.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0.88))
			else:
				img.set_pixel(x, y, fill)
	_stamp_glyph(img, center, kind)
	return ImageTexture.create_from_image(img)


func _stamp_glyph(img: Image, center: Vector2, kind: String) -> void:
	var white := Color(1, 1, 1, 0.95)
	if kind == "jump":
		_fill_triangle(img, center + Vector2(0, -28), center + Vector2(-26, 18), center + Vector2(26, 18), white)
		return
	var tip := -1.0 if kind == "left" else 1.0
	_fill_triangle(
		img,
		center + Vector2(28.0 * tip, 0),
		center + Vector2(-18.0 * tip, -26),
		center + Vector2(-18.0 * tip, 26),
		white
	)


func _fill_triangle(img: Image, a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
	var min_x := int(floor(minf(a.x, minf(b.x, c.x))))
	var max_x := int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var min_y := int(floor(minf(a.y, minf(b.y, c.y))))
	var max_y := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	min_x = clampi(min_x, 0, img.get_width() - 1)
	max_x = clampi(max_x, 0, img.get_width() - 1)
	min_y = clampi(min_y, 0, img.get_height() - 1)
	max_y = clampi(max_y, 0, img.get_height() - 1)
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			if _inside_triangle(Vector2(x + 0.5, y + 0.5), a, b, c):
				img.set_pixel(x, y, color)


func _inside_triangle(p: Vector2, a: Vector2, b: Vector2, c: Vector2) -> bool:
	var v0 := c - a
	var v1 := b - a
	var v2 := p - a
	var dot00 := v0.dot(v0)
	var dot01 := v0.dot(v1)
	var dot02 := v0.dot(v2)
	var dot11 := v1.dot(v1)
	var dot12 := v1.dot(v2)
	var denom := dot00 * dot11 - dot01 * dot01
	if is_zero_approx(denom):
		return false
	var u := (dot11 * dot02 - dot01 * dot12) / denom
	var v := (dot00 * dot12 - dot01 * dot02) / denom
	return u >= 0.0 and v >= 0.0 and u + v <= 1.0
