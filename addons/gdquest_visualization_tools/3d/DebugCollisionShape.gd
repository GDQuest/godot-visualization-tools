tool
class_name DebugCollisionShape
extends CollisionShape


enum ThemeType {WIREFRAME, HALO}

const SHADERS := {
	ThemeType.WIREFRAME: preload("shaders/Wireframe.tres"),
	ThemeType.HALO: preload("shaders/Halo.tres")
}
const THEME_FRESNEL_POWER_PROPERTY := {
	"name": "theme_fresnel_power",
	"type": TYPE_REAL,
	"hint": PROPERTY_HINT_RANGE,
	"hint_string": "0.01,5"
}
const THEME_EDGE_INTENSITY_PROPERTY := {
	"name": "theme_edge_intensity",
	"type": TYPE_REAL,
	"hint": PROPERTY_HINT_RANGE,
	"hint_string": "0.0,5"
}

var _palette_property := {
	"name": "palette",
	"type": TYPE_INT,
	"hint": PROPERTY_HINT_ENUM,
	"hint_string": DebugUtils.enum_to_string(DebugPalette.Type)
}
var _theme_property := {
	"name": "theme",
	"type": TYPE_INT,
	"hint": PROPERTY_HINT_ENUM,
	"hint_string": DebugUtils.enum_to_string(ThemeType)
}
var _material: ShaderMaterial
var _rids := {"meshes": [], "instances": []}
var _is_implemented := false
var _is_ready := false
var _previous_palette: int = DebugPalette.Type.INTERACT
var _palette: int = _previous_palette
var _theme: int = ThemeType.HALO
var _theme_fresnel_power := 1.0
var _theme_edge_intensity := 0.5


func _init() -> void:
	_material = ShaderMaterial.new()
	set_notify_transform(true)
	_set_palette(_palette)
	_set_theme_fresnel_power(_theme_fresnel_power)
	_set_theme_edge_intensity(_theme_edge_intensity)


func _ready() -> void:
	if not Engine.editor_hint:
		add_to_group("GVTCollision")
	_is_ready = true


func _enter_tree() -> void:
	refresh()


func _exit_tree() -> void:
	_free()


func _notification(what: int) -> void:
	if shape == null:
		return

	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			var xform := global_transform
			match [shape.get_class(), _theme]:
				["RayShape", ThemeType.HALO]:
					xform.origin = Vector3.ZERO
					xform = xform.rotated(global_transform.basis.x, PI / 2)
					xform.origin = global_transform.origin
					var midway: Vector3 = 0.5 * shape.length * Vector3.UP
					for rid in _rids.instances:
						xform = xform.translated(midway)
						VisualServer.instance_set_transform(rid, xform)
				_:
					for rid in _rids.instances:
						VisualServer.instance_set_transform(rid, xform)


func refresh() -> void:
	_is_implemented = false
	if shape == null:
		_free()
		return

	if not shape.is_connected("changed", self, "_draw"):
		shape.connect("changed", self, "_draw")
	_draw()
	property_list_changed_notify()


func _free() -> void:
	for key in _rids:
		for rid in _rids[key]:
			funcref(VisualServer, "free_rid").call_func(rid)
		_rids[key] = []


func _update_boxshape() -> Array:
	var mesh := CubeMesh.new()
	mesh.size = 2 * shape.extents
	return [mesh.get_mesh_arrays()]


func _update_cylindershape() -> Array:
	var mesh := CylinderMesh.new()
	mesh.top_radius = shape.radius
	mesh.bottom_radius = shape.radius
	mesh.height = shape.height
	return [mesh.get_mesh_arrays()]


func _update_capsuleshape() -> Array:
	var mesh := CapsuleMesh.new()
	mesh.radius = shape.radius
	mesh.mid_height = shape.height
	return [mesh.get_mesh_arrays()]


func _update_rayshape() -> Array:
	var result := []
	var mesh: PrimitiveMesh = CylinderMesh.new()
	mesh.top_radius = 0.01
	mesh.bottom_radius = mesh.top_radius
	mesh.height = shape.length
	result.push_back(mesh.get_mesh_arrays())

	mesh = SphereMesh.new()
	mesh.radius = 0.03
	mesh.height = 2 * mesh.radius
	result.push_back(mesh.get_mesh_arrays())
	return result


func _update_sphereshape() -> Array:
	var mesh := SphereMesh.new()
	mesh.radius = shape.radius
	mesh.height = 2 * shape.radius
	return [mesh.get_mesh_arrays()]


func _draw_meshes(mesh_info: Dictionary) -> void:
	var world := get_world()
	if mesh_info.empty() or world == null:
		return

	for array in mesh_info.arrays:
		var mesh_RID := VisualServer.mesh_create()
		VisualServer.mesh_add_surface_from_arrays(mesh_RID, mesh_info.primitive_type, array)
		VisualServer.mesh_surface_set_material(mesh_RID, 0, _material.get_rid())
		_rids.instances.push_back(VisualServer.instance_create2(mesh_RID, get_world().scenario))
		_rids.meshes.push_back(mesh_RID)
	_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _draw() -> void:
	_free()
	var method_name := "_update_%s" % [shape.get_class().to_lower()]
	_is_implemented = has_method(method_name)
	var meshes_info := {}
	match [_is_implemented, _theme]:
		[_, ThemeType.WIREFRAME]:
			var mesh := shape.get_debug_mesh()
			if mesh.get_surface_count() > 0:
				meshes_info = {
					"primitive_type": VisualServer.PRIMITIVE_LINES,
					"arrays": [mesh.surface_get_arrays(0)]
				}
		[true, ThemeType.HALO]:
			meshes_info = {
				"primitive_type": VisualServer.PRIMITIVE_TRIANGLES,
				"arrays": funcref(self, method_name).call_func()
			}
	_draw_meshes(meshes_info)


func _get(property: String):
	match property:
		"palette":
			return _palette
		"theme":
			return _theme
		"theme_fresnel_power":
			return _theme_fresnel_power
		"theme_edge_intensity":
			return _theme_edge_intensity


func _get_property_list() -> Array:
	if shape == null:
		return []

	var result := [_palette_property]
	match [_is_implemented, _theme]:
		[false, ThemeType.HALO]:
			_set_theme(ThemeType.WIREFRAME)
		[true, ThemeType.WIREFRAME]:
			result.push_back(_theme_property)
		[true, ThemeType.HALO]:
			result.append_array([_theme_property, THEME_FRESNEL_POWER_PROPERTY, THEME_EDGE_INTENSITY_PROPERTY])
	return result


func _set(property: String, value) -> bool:
	var result := false
	match property:
		"visible":
			set_visible(value)
		_:
			var method_name := "_set_%s" % [property]
			result = has_method(method_name) and funcref(self, method_name).call_func(value)
	return result


func _set_disabled_effect() -> void:
	if _palette != DebugPalette.Type.DISABLED:
		_previous_palette = _palette
	_material.set_shader_param("color", DebugPalette.COLORS[_palette])


func _set_disabled(new_is_disabled: bool) -> bool:
	_palette = DebugPalette.Type.DISABLED if new_is_disabled else _previous_palette
	_set_disabled_effect()
	return false


func _set_palette(new_palette: int) -> bool:
	_palette = new_palette
	set_deferred("disabled", _palette == DebugPalette.Type.DISABLED)
	_set_disabled_effect()
	return true


func _set_theme(new_theme: int) -> bool:
	_theme = new_theme
	_material.shader = SHADERS[_theme]
	_is_ready and refresh()
	return true


func _set_theme_fresnel_power(new_theme_fresnel_power: float) -> bool:
	_theme_fresnel_power = new_theme_fresnel_power
	_material.set_shader_param("fresnel_power", _theme_fresnel_power)
	return true


func _set_theme_edge_intensity(new_theme_edge_intensity: float) -> bool:
	_theme_edge_intensity = new_theme_edge_intensity
	_material.set_shader_param("edge_intensity", _theme_edge_intensity)
	return true


func set_visible(new_visible: bool) -> void:
	visible = new_visible
	for rid in _rids.instances:
		VisualServer.instance_set_visible(rid, new_visible)
