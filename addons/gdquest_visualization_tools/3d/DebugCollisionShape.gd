tool
class_name DebugCollisionShape
extends CollisionShape


const HALO_SHADER := preload("shaders/Halo.tres")

var _mesh: Mesh
var _material: ShaderMaterial
var _rids := {
	"mesh": RID(),
	"instance": RID()
}


func _enter_tree() -> void:
	if not Engine.editor_hint:
		add_to_group("GVTCollision3D")

	_material = ShaderMaterial.new()
	_material.shader = HALO_SHADER
	set_notify_transform(true)
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
	if shape != null:
		if not shape.is_connected("changed", self, "_draw"):
			shape.connect("changed", self, "_draw")
		_draw()
	else:
		_exit_tree()


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
	if has_method(method_name):
		funcref(self, method_name).call_func()
		_draw_mesh()
		_notification(NOTIFICATION_TRANSFORM_CHANGED)
