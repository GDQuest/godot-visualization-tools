tool
class_name DebugCollisionPolygon
extends CollisionPolygon


enum ThemeType {WIREFRAME, HALO}

const SHADERS := {
	ThemeType.WIREFRAME: preload("shaders/Wireframe.tres"),
	ThemeType.HALO: preload("shaders/Halo.tres")
}

export(ThemeType) var theme := ThemeType.HALO setget set_theme

var _rids := []
var _material := ShaderMaterial.new()
var _is_ready := false


func _ready() -> void:
	if not Engine.editor_hint:
		add_to_group("GVTCollision")

	_is_ready = true
	set_notify_transform(true)
	set_theme(theme)


func _enter_tree() -> void:
	_draw()


func _exit_tree() -> void:
	_free()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			VisualServer.instance_set_transform(_rids[1], global_transform)


func _free() -> void:
	for rid in _rids:
		VisualServer.free_rid(rid)
	_rids.clear()


func _draw() -> void:
	var polygon_size := polygon.size()
	if polygon_size < 3:
		return

	_free()
	var is_drawn := false
	match theme:
		ThemeType.WIREFRAME:
			var complete_polygon := []
			for point in polygon:
				for direction in [-1, 1]:
					complete_polygon.push_back(Vector3(point.x, point.y, 0.5 * depth * direction))
			var convex_polygon_shape := ConvexPolygonShape.new()
			convex_polygon_shape.points = complete_polygon
			var mesh := convex_polygon_shape.get_debug_mesh()
			if mesh.get_surface_count() > 0:
				_rids.push_back(VisualServer.mesh_create())
				VisualServer.mesh_add_surface_from_arrays(_rids[0], VisualServer.PRIMITIVE_LINES, mesh.surface_get_arrays(0))
				VisualServer.mesh_surface_set_material(_rids[0], 0, _material.get_rid())
				is_drawn = true

		ThemeType.HALO:
			_rids.push_back(VisualServer.immediate_create())
			for direction in [-1, 1]:
				VisualServer.immediate_begin(_rids[0], VisualServer.PRIMITIVE_TRIANGLE_FAN)
				VisualServer.immediate_normal(_rids[0], Vector3.BACK)
				for point in polygon:
					VisualServer.immediate_vertex(_rids[0], Vector3(point.x, point.y, 0.5 * depth * direction))
				VisualServer.immediate_end(_rids[0])

			var closed_polygon := Array(polygon) + [polygon[0]]
			for index in range(polygon_size):
				VisualServer.immediate_begin(_rids[0], VisualServer.PRIMITIVE_TRIANGLE_FAN)
				var level := 0.5 * depth
				var v0 := Vector3(closed_polygon[index].x, closed_polygon[index].y, -level)
				var v1 := Vector3(closed_polygon[index + 1].x, closed_polygon[index + 1].y, -level)
				var v2 := Vector3(closed_polygon[index + 1].x, closed_polygon[index + 1].y, level)
				var normal := (v1 - v0).cross(v1 - v2).normalized()
				VisualServer.immediate_normal(_rids[0], normal)
				VisualServer.immediate_vertex(_rids[0], v0)
				VisualServer.immediate_vertex(_rids[0], v1)
				VisualServer.immediate_vertex(_rids[0], v2)
				VisualServer.immediate_vertex(_rids[0], Vector3(closed_polygon[index].x, closed_polygon[index].y, level))
				VisualServer.immediate_end(_rids[0])
				VisualServer.immediate_set_material(_rids[0], _material.get_rid())
			is_drawn = true

	if is_drawn:
		_rids.push_back(VisualServer.instance_create2(_rids[0], get_world().scenario))
		_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _set(property: String, value) -> bool:
	var method_name := "set_%s" % [property]
	has_method(method_name) and funcref(self, method_name).call_func(value)
	return false


func set_depth(new_depth: float) -> void:
	depth = new_depth
	_draw()


func set_polygon(new_polygon: PoolVector2Array) -> void:
	polygon = new_polygon
	_draw()


func set_theme(new_theme: int) -> void:
	theme = new_theme
	_material.shader = SHADERS[theme]
	_is_ready and _draw()
