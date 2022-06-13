tool
class_name DebugRayCast
extends RayCast


const DebugUtils := preload("../DebugUtils.gd")
const DebugPalette := preload("../DebugPalette.gd")
const DebugCollisionTheme := preload("DebugCollisionTheme.gd")

export(DebugPalette.Type) var palette := DebugPalette.Type.INTERACT setget set_palette
export(DebugCollisionTheme.ThemeType) var theme := DebugCollisionTheme.ThemeType.HALO setget set_theme

var _rids := {"resources": [], "instances": []}
var _previous_palette: int = palette
var _material := ShaderMaterial.new()
var _cast_to := cast_to


func _ready() -> void:
	set_palette(palette)
	set_theme(theme)
	set_notify_transform(true)
	if not Engine.editor_hint:
		add_to_group("GVTCollision")


func _enter_tree() -> void:
	_draw()


func _exit_tree() -> void:
	_free()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			var xform := global_transform
			match theme:
				DebugCollisionTheme.ThemeType.WIREFRAME:
					if not _rids.instances.empty():
						xform.origin = Vector3.ZERO
						xform = xform.rotated(transform.basis.x, PI / 2)
						xform.origin = global_transform.origin
						VisualServer.instance_set_transform(_rids.instances[0], xform)
						VisualServer.instance_set_transform(_rids.instances[1], transform.translated(_cast_to.length() * Vector3.DOWN))
#					for rid in _rids.instances:
#						VisualServer.instance_set_transform(rid, xform)
#						xform = transform.translated(_cast_to.length() * Vector3.DOWN)

				DebugCollisionTheme.ThemeType.HALO:
					var midway: Vector3 = 0.5 * _cast_to.length() * Vector3.DOWN
					for rid in _rids.instances:
						xform = xform.translated(midway)
						VisualServer.instance_set_transform(rid, xform)


func _physics_process(delta: float) -> void:
	if is_colliding():
		_material.set_shader_param("color", DebugPalette.COLORS[palette].contrasted())
		_cast_to = transform.xform_inv(get_collision_point())
	else:
		_material.set_shader_param("color", DebugPalette.COLORS[palette])
		_cast_to = cast_to
	_draw()


func _free() -> void:
	for key in _rids:
		for rid in _rids[key]:
			funcref(VisualServer, "free_rid").call_func(rid)
		_rids[key].clear()


func _draw() -> void:
	if not visible:
		return

	_free()
	var meshes_info := {"arrays": []}
	match theme:
		DebugCollisionTheme.ThemeType.WIREFRAME:
			var shape: Shape = RayShape.new()
			shape.length = _cast_to.length()
			var mesh := shape.get_debug_mesh()
			if mesh.get_surface_count() > 0:
				meshes_info.arrays.push_back(mesh.surface_get_arrays(0))
				shape = SphereShape.new()
				shape.radius = 0.03
				meshes_info.arrays.push_back(shape.get_debug_mesh().surface_get_arrays(0))
				meshes_info.primitive_type = VisualServer.PRIMITIVE_LINES

		DebugCollisionTheme.ThemeType.HALO:
			var mesh: PrimitiveMesh = CylinderMesh.new()
			mesh.top_radius = 0.01
			mesh.bottom_radius = mesh.top_radius
			mesh.height = _cast_to.length()
			mesh.radial_segments = 4
			mesh.rings = 0
			meshes_info.arrays.push_back(mesh.get_mesh_arrays())
			mesh = SphereMesh.new()
			mesh.radius = 0.03
			mesh.height = 2 * mesh.radius
			mesh.radial_segments = 16
			mesh.rings = 8
			meshes_info.arrays.push_back(mesh.get_mesh_arrays())
			meshes_info.primitive_type = VisualServer.PRIMITIVE_TRIANGLES

	if not meshes_info.arrays.empty():
		_rids = DebugUtils.draw_meshes(meshes_info.primitive_type, meshes_info.arrays, _material.get_rid(), get_world().scenario)
		_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _set_enabled_effect() -> void:
	_material.set_shader_param("color", DebugPalette.COLORS[palette])
	if palette != DebugPalette.Type.DISABLED:
		_previous_palette = palette


func _set(property: String, value) -> bool:
	match property:
		"visible": set_visible(value)
		"enabled":
			palette = _previous_palette if value else DebugPalette.Type.DISABLED
			_set_enabled_effect()
	return false


func set_palette(new_palette: int) -> void:
	palette = new_palette
	set_deferred("enabled", palette != DebugPalette.Type.DISABLED)
	_set_enabled_effect()


func set_theme(new_theme: int) -> void:
	theme = new_theme
	_material.shader = DebugCollisionTheme.SHADERS[theme]


func set_visible(new_visible: bool) -> void:
	visible = new_visible
	set_notify_transform(visible)
	for rid in _rids.instances:
		VisualServer.instance_set_visible(rid, visible)
