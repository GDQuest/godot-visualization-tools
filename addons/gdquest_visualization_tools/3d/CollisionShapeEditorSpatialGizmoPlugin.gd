extends EditorSpatialGizmoPlugin


const HALO_SHADER := preload("shaders/Halo.tres")

var _cube_mesh := CubeMesh.new()


func _init() -> void:
	_cube_mesh.material = ShaderMaterial.new()
	_cube_mesh.material.shader = HALO_SHADER


func redraw(gizmo: EditorSpatialGizmo) -> void:
	gizmo.clear()
	gizmo.add_mesh(_cube_mesh)
	var collision_shape: CollisionShape = gizmo.get_spatial_node()
	gizmo.add_collision_segments([Vector3.ZERO, 10 * Vector3.UP])
#	print(collision_shape.name, _cube_mesh)
#	var lines := PoolVector3Array()
#	lines.push_back(Vector3(0, 10, 0))
#	lines.push_back(Vector3(0, -10, 0))
#	gizmo.add_lines(lines, get_material("main", gizmo))


func has_gizmo(spatial: Spatial) -> bool:
	return spatial is CollisionShape


func get_name() -> String:
	return "CollisionShape"
