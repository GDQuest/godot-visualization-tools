@tool
class_name DebugPath2D
extends Path2D

const DebugPalette := preload("../DebugPalette.gd")

const TRIANGLE_COG_DISTANCE := 10
const DEFAULT_THEME_WIDTH := 4
const COLOR := DebugPalette.COLORS[DebugPalette.Type.INTERACT]

@export_range(1, 10) var width := DEFAULT_THEME_WIDTH:
	set(value):
		width = value
		_xform_scale = width / float(DEFAULT_THEME_WIDTH) * Vector2.ONE
@export_range(1, 500) var spread := 100.0

var _triangle_vertices := PackedVector2Array([TRIANGLE_COG_DISTANCE * (Vector2.LEFT + Vector2.UP).normalized(), TRIANGLE_COG_DISTANCE * (Vector2.LEFT + Vector2.DOWN).normalized(), TRIANGLE_COG_DISTANCE * Vector2.RIGHT])
var _xform_scale := width / float(DEFAULT_THEME_WIDTH) * Vector2.ONE


func _init():
	self_modulate = COLOR


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("GVTNavigation")


func _draw() -> void:
	var points := curve.get_baked_points()
	if points.is_empty():
		return

	RenderingServer.canvas_item_clear(get_canvas_item())
	draw_polyline(points, Color.WHITE, width)
	draw_arc(points[0], 3 * width, 0, TAU, 24, Color.WHITE, width / 2.0)
	draw_circle(points[-1], 3 * width, Color.WHITE)

	var triangles := int(curve.get_baked_length() / spread)
	var unit := curve.get_baked_length() / triangles
	for index in range(1, triangles):
		var t := index * unit
		var offset := curve.sample_baked(t)
		var direction := offset - curve.sample_baked(t - 1)
		var xform := Transform2D.IDENTITY.scaled(_xform_scale).rotated(direction.angle())
		xform.origin = offset
		draw_primitive(xform * _triangle_vertices, [Color.WHITE], [])
