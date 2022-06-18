tool
class_name DebugPath
extends Path


const DebugUtils := preload("../DebugUtils.gd")
const DebugTheme := preload("DebugTheme.gd")

const DELTA := 0.01
const MAX_SAMPLES := 100

export(int, 0, 100) var samples := 10 setget set_samples

var _theme := DebugTheme.new(self)
var _spheres := [SphereShape.new(), SphereMesh.new()]
var _pointer := CylinderMesh.new()
var _pointer_mesh_RID := RID()
var _pointer_multimesh_RID := RID()
var _pointer_instance_RID := RID()


func _init() -> void:
	_theme.theme = DebugTheme.ThemeType.WIREFRAME
	_spheres[0].radius = 0.03
	_spheres[1].radius = 0.03
	_spheres[1].height = 2 * _spheres[1].radius
	_spheres[1].radial_segments = 16
	_spheres[1].rings = 8
	_pointer.top_radius = 0
	_pointer.bottom_radius = 2 * 0.03
	_pointer.height = 2 * _pointer.bottom_radius
	_pointer.radial_segments = 4
	_pointer.rings = 0


func _ready() -> void:
	connect("curve_changed", self, "refresh")
	set_notify_transform(true)
	if not Engine.editor_hint:
		add_to_group("GVTNavigation")


func _enter_tree() -> void:
	_draw()


func _exit_tree() -> void:
	_theme.free_rids()
	_free_pointer_rids()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_TRANSFORM_CHANGED:
			var xform := global_transform
			VisualServer.instance_set_transform(_theme.rids.instances[0], xform)
			xform.origin = global_transform.xform(curve.get_point_position(0))
			VisualServer.instance_set_transform(_theme.rids.instances[1], xform)
			xform.origin = global_transform.xform(curve.get_point_position(curve.get_point_count() - 1))
			VisualServer.instance_set_transform(_theme.rids.instances[2], xform)

			var unit := curve.get_baked_length() / (samples + 1)
			for index in range(samples):
				var t := (index + 1) * unit
				var offset := curve.interpolate_baked(t)
				var direction: Vector3 = global_transform.xform(offset - curve.interpolate_baked(t - DELTA))
				xform = global_transform.looking_at(DebugUtils.v3normal(direction), direction)
				xform.origin = global_transform.xform(offset)
				VisualServer.multimesh_instance_set_transform(_pointer_multimesh_RID, index, xform)


func refresh() -> void:
	_draw()
	property_list_changed_notify()


func _free_pointer_rids() -> void:
	VisualServer.free_rid(_pointer_mesh_RID)
	VisualServer.free_rid(_pointer_multimesh_RID)
	VisualServer.free_rid(_pointer_instance_RID)



func _draw() -> void:
	if not visible:
		return

	match _theme.theme:
		DebugTheme.ThemeType.WIREFRAME:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_LINES)
			for sample in range(curve.get_baked_length() / curve.bake_interval):
				st.add_vertex(curve.interpolate_baked(sample * curve.bake_interval))
			st.add_vertex(curve.interpolate_baked(curve.get_baked_length()))

			var meshes_info := {"primitive_types": [], "arrays": []}
			meshes_info.primitive_types.push_back(VisualServer.PRIMITIVE_LINE_STRIP)
			meshes_info.arrays.push_back(st.commit_to_arrays())
			meshes_info.primitive_types.push_back(VisualServer.PRIMITIVE_LINES)
			meshes_info.arrays.push_back(_spheres[0].get_debug_mesh().surface_get_arrays(0))
			meshes_info.primitive_types.push_back(VisualServer.PRIMITIVE_TRIANGLES)
			meshes_info.arrays.push_back(_spheres[1].get_mesh_arrays())
			_theme.draw_meshes(meshes_info)

			_free_pointer_rids()
			_pointer_mesh_RID = VisualServer.mesh_create()
			VisualServer.mesh_add_surface_from_arrays(_pointer_mesh_RID, VisualServer.PRIMITIVE_LINES, _pointer.get_mesh_arrays())
			VisualServer.mesh_surface_set_material(_pointer_mesh_RID, 0, _theme.material.get_rid())
			_pointer_multimesh_RID = VisualServer.multimesh_create()
			VisualServer.multimesh_set_mesh(_pointer_multimesh_RID, _pointer_mesh_RID)
			VisualServer.multimesh_allocate(_pointer_multimesh_RID, MAX_SAMPLES, VisualServer.MULTIMESH_TRANSFORM_3D, VisualServer.MULTIMESH_COLOR_NONE)
			_pointer_instance_RID = VisualServer.instance_create2(_pointer_multimesh_RID, get_world().scenario)

			_notification(NOTIFICATION_TRANSFORM_CHANGED)


func _get(property: String):
	return _theme.get_property(property)


func _get_property_list() -> Array:
	return _theme.get_property_list()


func _set(property: String, value) -> bool:
	var result := false
	match property:
		"visible": set_visible(value)
		_: result = _theme != null and _theme.set_property(property, value)
	return result


func set_visible(new_visible: bool) -> void:
	visible = new_visible
	_theme.set_visible(new_visible)


func set_samples(new_samples: int) -> void:
	samples = new_samples
	_notification(NOTIFICATION_TRANSFORM_CHANGED)
