@tool
class_name DebugRayCast2D
extends RayCast2D

enum ThemeType { SIMPLE, DASHED }

const DebugUtils := preload("../DebugUtils.gd")
const DebugPalette := preload("../DebugPalette.gd")

const THEME_SAMPLE := 48

@export var palette: DebugPalette.Type = DebugPalette.Type.INTERACT:
	set(value):
		palette = value
		enabled = palette != DebugPalette.Type.DISABLED
		_set_enabled_effect()
@export var theme: ThemeType = ThemeType.SIMPLE
@export_range(0, 10) var theme_width := 4

var _previous_palette: int = palette
var _color: Color = DebugPalette.COLORS[palette]
var _target_position := target_position


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("GVTCollision")


func _physics_process(delta: float) -> void:
	if is_colliding():
		_color = DebugPalette.COLORS[palette].inverted()
		_target_position = get_collision_point() * transform
	else:
		_color = DebugPalette.COLORS[palette]
		_target_position = target_position


func _draw() -> void:
	if not visible:
		return

	draw_circle(_target_position, theme_width, _color)
	match theme:
		ThemeType.SIMPLE:
			draw_line(Vector2.ZERO, _target_position, _color, theme_width)
			draw_arc(_target_position, 3 * theme_width, 0, TAU, THEME_SAMPLE, _color, theme_width / 2)
		ThemeType.DASHED:
			DebugUtils.draw_polyline_dashed(self, _get_curve_line(), _color, theme_width, THEME_SAMPLE)
			var circle_curve := DebugUtils.get_curve_circle(3 * theme_width, THEME_SAMPLE / 2, Transform2D.IDENTITY.translated(_target_position))
			DebugUtils.draw_polyline_dashed(self, circle_curve, _color, theme_width / 2, THEME_SAMPLE)


func _get_curve_line() -> Curve2D:
	var result := Curve2D.new()
	result.add_point(Vector2.ZERO)
	result.add_point(_target_position)
	return result


func _set_enabled_effect() -> void:
	if palette != DebugPalette.Type.DISABLED:
		_previous_palette = palette
	_color = DebugPalette.COLORS[palette]


func _set(property: StringName, value: Variant) -> bool:
	match property:
		"enabled":
			palette = _previous_palette if value else DebugPalette.Type.DISABLED
			_set_enabled_effect()
	return false
