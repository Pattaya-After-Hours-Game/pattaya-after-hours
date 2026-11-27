extends Button

# Compact notifications own their complete theme instead of inheriting the
# full-size action button's minimum height, wrapping and primary colours.
enum Kind { COUNT, WARNING, ALERT }

const GREEN = Color("#71f9d2")
const YELLOW = Color("#ffe45c")
const RED = Color("#b8293d")
const INK = Color("#111d22")
const BORDER = Color("#241820")
const BADGE_SIZE = Vector2(21,21)

func _init(kind: Kind = Kind.COUNT, count: int = 0) -> void:
	custom_minimum_size = BADGE_SIZE
	size = BADGE_SIZE
	z_index = 2
	autowrap_mode = TextServer.AUTOWRAP_OFF
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_font_size_override("font_size",11)
	set_status(kind,count)

func set_status(kind: Kind, count: int = 0) -> void:
	text = str(count) if kind==Kind.COUNT else "!"
	var fill: Color = [GREEN,YELLOW,RED][kind]
	var ink := Color.WHITE if kind==Kind.ALERT else INK
	for state in ["normal","hover","pressed","disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = fill.lightened(.12) if state=="hover" else fill.darkened(.12) if state=="pressed" else fill
		style.border_color = BORDER
		style.set_border_width_all(2)
		style.set_corner_radius_all(10)
		style.content_margin_left = 3
		style.content_margin_right = 3
		add_theme_stylebox_override(state,style)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_disabled_color"]:
		add_theme_color_override(state,ink)
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = Color.WHITE
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(10)
	add_theme_stylebox_override("focus",focus)
