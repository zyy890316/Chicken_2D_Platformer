extends Control

var _speaker: Node2D
var _offset := Vector2.ZERO
var _label: Label
var _panel: PanelContainer


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 20
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.96)
	style.border_color = Color(0.22, 0.16, 0.12, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.custom_minimum_size = Vector2(160, 0)
	_label.add_theme_font_size_override("font_size", 16)
	_label.add_theme_color_override("font_color", Color(0.15, 0.12, 0.1, 1))
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel.add_child(_label)

	var tail := Polygon2D.new()
	tail.color = Color(1, 1, 1, 0.96)
	tail.polygon = PackedVector2Array([
		Vector2(-8, -2),
		Vector2(8, -2),
		Vector2(0, 10),
	])
	tail.z_index = 1
	add_child(tail)
	modulate.a = 0.0


func follow(speaker: Node2D, text: String, offset: Vector2) -> void:
	_speaker = speaker
	_offset = offset
	_label.text = text
	_panel.reset_size()
	_update_placement()
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.18)


func _process(_delta: float) -> void:
	_update_placement()


func _update_placement() -> void:
	if _speaker == null or not is_instance_valid(_speaker):
		return
	var screen := _speaker.get_global_transform_with_canvas().origin + _offset
	var size := _panel.get_combined_minimum_size()
	if size.x < 40.0:
		size = Vector2(180, 48)
	position = screen - Vector2(size.x * 0.5, size.y + 14)
	var tail := get_child(1) as Polygon2D
	if tail != null:
		tail.position = Vector2(size.x * 0.5, size.y - 2)
