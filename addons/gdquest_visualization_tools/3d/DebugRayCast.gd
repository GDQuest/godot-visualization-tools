@tool
class_name DebugRayCast
extends RayCast3D

const DebugUtils := preload("../DebugUtils.gd")
const DebugPalette := preload("../DebugPalette.gd")
const DebugTheme := preload("DebugTheme.gd")

var _theme := DebugTheme.new(self)
var _target_position := target_position


func _ready() -> void:
	set_notify_transform(true)
	if not Engine.is_editor_hint():
		add_to_group("GVTCollision")


func _enter_tree() -> void:
	_draw()


func _exit_tree() -> void:
	_theme.free_rids()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			var xform := global_transform
			var global_target_position: Vector3 = xform * _target_position
			var global_target_position_normal = DebugUtils.v3normal(global_target_position)
			xform = xform.looking_at(global_target_position, global_target_position_normal)

			match _theme.theme:
				DebugTheme.ThemeType.WIREFRAME:
					if not _theme.rids.instances.is_empty():
						xform = xform.translated(_target_position.length() * Vector3.FORWARD)
						for rid in _theme.rids.instances:
							RenderingServer.instance_set_transform(rid, xform)
							RenderingServer.instance_set_transform(rid, xform)

				DebugTheme.ThemeType.HALO:
					xform.origin = Vector3.ZERO
					xform = xform.rotated(xform.basis.x, PI / 2)
					xform.origin = global_transform.origin
					var midway: Vector3 = 0.5 * _target_position.length() * Vector3.DOWN
					for rid in _theme.rids.instances:
						xform = xform.translated(midway)
						RenderingServer.instance_set_transform(rid, xform)


func _physics_process(delta: float) -> void:
	if is_colliding():
		_theme.material.set_shader_parameter("color", DebugPalette.COLORS[_theme.palette].contrasted())
		_target_position = get_collision_point() * transform
	else:
		_theme.material.set_shader_parameter("color", DebugPalette.COLORS[_theme.palette])
		_target_position = target_position
	_draw()


func refresh() -> void:
	_draw()
	notify_property_list_changed()


func _draw() -> void:
	if not visible:
		return

	var meshes_info := []
	match _theme.theme:
		DebugTheme.ThemeType.WIREFRAME:
			var shape: Shape3D = SeparationRayShape3D.new()
			shape.length = _target_position.length()
			var mesh := shape.get_debug_mesh()
			if mesh.get_surface_count() > 0:
				meshes_info.push_back({"primitive_type": RenderingServer.PRIMITIVE_LINES, "arrays": mesh.surface_get_arrays(0)})
				shape = SphereShape3D.new()
				shape.radius = 0.03
				meshes_info.push_back({"primitive_type": RenderingServer.PRIMITIVE_LINES, "arrays": shape.get_debug_mesh().surface_get_arrays(0)})

		DebugTheme.ThemeType.HALO:
			var mesh: PrimitiveMesh = CylinderMesh.new()
			mesh.top_radius = 0.01
			mesh.bottom_radius = mesh.top_radius
			mesh.height = _target_position.length()
			mesh.radial_segments = 4
			mesh.rings = 0
			meshes_info.push_back({"primitive_type": RenderingServer.PRIMITIVE_TRIANGLES, "arrays": mesh.get_mesh_arrays()})
			mesh = SphereMesh.new()
			mesh.radius = 0.03
			mesh.height = 2 * mesh.radius
			mesh.radial_segments = 16
			mesh.rings = 8
			meshes_info.push_back({"primitive_type": RenderingServer.PRIMITIVE_TRIANGLES, "arrays": mesh.get_mesh_arrays()})

	if not meshes_info.is_empty():
		_theme.draw_meshes(meshes_info)
		_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _get(property: StringName) -> Variant:
	return _theme.get_property(property)


func _get_property_list() -> Array:
	return _theme.get_property_list()


func _set(property: StringName, value: Variant) -> bool:
	var result := false
	match property:
		"visible":
			set_visible(value)
		_:
			result = _theme != null and _theme.set_property(property, value)
	return result


func set_visible(new_visible: bool) -> void:
	visible = new_visible
	_theme.set_visible(new_visible)
