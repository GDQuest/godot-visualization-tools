tool
class_name DebugCollisionShape
extends CollisionShape


const DebugCollisionTheme := preload("DebugCollisionTheme.gd")

var _theme := DebugCollisionTheme.new(self)


func _ready() -> void:
	if not Engine.editor_hint:
		add_to_group("GVTCollision")
	_theme.setup()


func _enter_tree() -> void:
	refresh()


func _exit_tree() -> void:
	_theme.free_rids()


func _notification(what: int) -> void:
	if shape == null:
		return

	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			var xform := global_transform
			match [shape.get_class(), _theme.theme]:
				["RayShape", DebugCollisionTheme.ThemeType.HALO]:
					xform.origin = Vector3.ZERO
					xform = xform.rotated(global_transform.basis.x, PI / 2)
					xform.origin = global_transform.origin
					var midway: Vector3 = 0.5 * shape.length * Vector3.UP
					for rid in _theme.rids.instances:
						xform = xform.translated(midway)
						VisualServer.instance_set_transform(rid, xform)
				_:
					for rid in _theme.rids.instances:
						VisualServer.instance_set_transform(rid, xform)


func refresh() -> void:
	if shape == null:
		return

	_theme.is_implemented = false
	if not shape.is_connected("changed", self, "_draw"):
		shape.connect("changed", self, "_draw")
	_draw()
	property_list_changed_notify()


func _update_boxshape() -> Array:
	var mesh := CubeMesh.new()
	mesh.size = 2 * shape.extents
	return [mesh.get_mesh_arrays()]


func _update_cylindershape() -> Array:
	var mesh := CylinderMesh.new()
	mesh.top_radius = shape.radius
	mesh.bottom_radius = shape.radius
	mesh.height = shape.height
	mesh.radial_segments = 32
	mesh.rings = 0
	return [mesh.get_mesh_arrays()]


func _update_capsuleshape() -> Array:
	var mesh := CapsuleMesh.new()
	mesh.radius = shape.radius
	mesh.mid_height = shape.height
	mesh.radial_segments = 32
	return [mesh.get_mesh_arrays()]


func _update_rayshape() -> Array:
	var result := []
	var mesh: PrimitiveMesh = CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = mesh.top_radius
	mesh.height = shape.length
	mesh.radial_segments = 4
	mesh.rings = 0
	result.push_back(mesh.get_mesh_arrays())

	mesh = SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 2 * mesh.radius
	mesh.radial_segments = 16
	mesh.rings = 8
	result.push_back(mesh.get_mesh_arrays())
	return result


func _update_sphereshape() -> Array:
	var mesh := SphereMesh.new()
	mesh.radius = shape.radius
	mesh.height = 2 * shape.radius
	mesh.radial_segments = 32
	mesh.rings = 16
	return [mesh.get_mesh_arrays()]


func _draw_meshes(mesh_info: Dictionary) -> void:
	var world := get_world()
	if mesh_info.empty() or world == null:
		return

	for array in mesh_info.arrays:
		var mesh_RID := VisualServer.mesh_create()
		VisualServer.mesh_add_surface_from_arrays(mesh_RID, mesh_info.primitive_type, array)
		VisualServer.mesh_surface_set_material(mesh_RID, 0, _theme.material.get_rid())
		_theme.rids.instances.push_back(VisualServer.instance_create2(mesh_RID, get_world().scenario))
		_theme.rids.resources.push_back(mesh_RID)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _draw() -> void:
	_theme.free_rids()
	var method_name := "_update_%s" % [shape.get_class().to_lower()]
	_theme.is_implemented = has_method(method_name)
	var meshes_info := {}
	match [_theme.is_implemented, _theme.theme]:
		[_, DebugCollisionTheme.ThemeType.WIREFRAME]:
			var mesh := shape.get_debug_mesh()
			if mesh.get_surface_count() > 0:
				meshes_info = {
					"primitive_type": VisualServer.PRIMITIVE_LINES,
					"arrays": [mesh.surface_get_arrays(0)]
				}
		[true, DebugCollisionTheme.ThemeType.HALO]:
			meshes_info = {
				"primitive_type": VisualServer.PRIMITIVE_TRIANGLES,
				"arrays": funcref(self, method_name).call_func()
			}
	_draw_meshes(meshes_info)


func _get(property: String):
	return _theme.get_property(property)


func _get_property_list() -> Array:
	return [] if shape == null else _theme.get_property_list()


func _set(property: String, value) -> bool:
	var result := false
	match property:
		"visible": set_visible(value)
		_: result = _theme != null and _theme.set_property(property, value)
	return result


func set_visible(new_visible: bool) -> void:
	visible = new_visible
	_theme.set_visible(visible)
