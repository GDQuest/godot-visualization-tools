tool
class_name DebugCollisionShape
extends CollisionShape


enum ThemeType {SIMPLE, HALO}

const HALO_SHADER := preload("shaders/Halo.tres")
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
var _mesh: Mesh
var _material: ShaderMaterial
var _rids := {"mesh": RID(), "instance": RID()}
var _palette: int = DebugPalette.Type.INTERACT
var _theme: int = ThemeType.HALO
var _theme_fresnel_power := 1.0
var _theme_edge_intensity := 0.5
var _is_implemented := false


func _init() -> void:
	_material = ShaderMaterial.new()
	_material.shader = HALO_SHADER
	set_notify_transform(true)
	_set_palette(_palette)
	_set_theme_fresnel_power(_theme_fresnel_power)
	_set_theme_edge_intensity(_theme_edge_intensity)


func _ready() -> void:
	if not Engine.editor_hint:
		add_to_group("GVTCollision3D")
	refresh()


func _exit_tree() -> void:
	for rid in _rids.values():
		funcref(VisualServer, "free_rid").call_func(rid)


func _notification(what: int) -> void:
	if not (shape != null and has_method("_update_%s" % [shape.get_class().to_lower()])):
		return

	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			VisualServer.instance_set_transform(_rids.instance, global_transform)


func refresh() -> void:
	_is_implemented = false
	if shape == null:
		_exit_tree()

	if not shape.is_connected("changed", self, "_draw"):
		shape.connect("changed", self, "_draw")
	_draw()
	property_list_changed_notify()


func _update_boxshape() -> void:
	_mesh = CubeMesh.new()
	_mesh.size = 2 * shape.extents


func _update_capsuleshape() -> void:
	_mesh = CapsuleMesh.new()
	_mesh.radius = shape.radius
	_mesh.mid_height = shape.height


func _update_sphereshape() -> void:
	_mesh = SphereMesh.new()
	_mesh.radius = shape.radius
	_mesh.height = 2 * shape.radius


func _draw_mesh() -> void:
	_rids.mesh = VisualServer.mesh_create()
	VisualServer.mesh_add_surface_from_arrays(_rids.mesh, VisualServer.PRIMITIVE_TRIANGLES, _mesh.get_mesh_arrays())
	VisualServer.mesh_surface_set_material(_rids.mesh, 0, _material.get_rid())
	_rids.instance = VisualServer.instance_create2(_rids.mesh, get_world().scenario)


func _draw() -> void:
	_exit_tree()
	var method_name := "_update_%s" % [shape.get_class().to_lower()]
	_is_implemented = has_method(method_name)
	if _is_implemented:
		funcref(self, method_name).call_func()
		_draw_mesh()
		_notification(NOTIFICATION_TRANSFORM_CHANGED)


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
	var result := []
	match [_is_implemented, _theme]:
		[true, ThemeType.HALO]:
			result = [_palette_property, _theme_property, THEME_FRESNEL_POWER_PROPERTY, THEME_EDGE_INTENSITY_PROPERTY]
#		[false, _, _]:
#			result = [_palette_property]
#		[true, ThemeType.HALO, _]:
#			result = [_palette_property, _theme_property, THEME_FALLOFF]
#		[true, _, 0]:
#			result = [_palette_property, _theme_property, THEME_WIDTH]
#		_:
#			result = [_palette_property, _theme_property, THEME_WIDTH, THEME_SAMPLE]
	return result


func _set(property: String, value) -> bool:
	var method_name := "_set_%s" % [property]
	return has_method(method_name) and funcref(self, method_name).call_func(value)


func _set_palette(new_palette: int) -> bool:
	_palette = new_palette
	_material.set_shader_param("color", DebugPalette.COLORS[_palette])
	return true


func _set_theme_fresnel_power(new_theme_fresnel_power: float) -> bool:
	_theme_fresnel_power = new_theme_fresnel_power
	_material.set_shader_param("fresnel_power", _theme_fresnel_power)
	return true


func _set_theme_edge_intensity(new_theme_edge_intensity: float) -> bool:
	_theme_edge_intensity = new_theme_edge_intensity
	_material.set_shader_param("edge_intensity", _theme_edge_intensity)
	return true
