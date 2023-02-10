@tool
extends EditorPlugin

const DebugCollisionPolygon3D := preload("3d/DebugCollisionPolygon3D.gd")
const DebugCollisionShape3D := preload("3d/DebugCollisionShape3D.gd")
const DebugRayCast3D := preload("3d/DebugRayCast3D.gd")


func _enter_tree() -> void:
	get_editor_interface().get_inspector().connect("property_edited",Callable(self,"_on_EditorInspector_property_edited"))
	add_autoload_singleton("GDQuestVisualizationTools", "res://addons/gdquest_visualization_tools/GDQuestVisualizationTools.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("GDQuestVisualizationTools")


func _on_EditorInspector_property_edited(property: String) -> void:
	match property:
		"shape":
			var selected_nodes := get_editor_interface().get_selection().get_selected_nodes()
			for node in selected_nodes:
				if node is DebugCollisionShape3D or node is DebugCollisionPolygon3D or node is DebugRayCast3D:
					node.refresh()
					node.notify_property_list_changed()
