@tool
extends EditorPlugin


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
				if node is DebugCollisionShape or node is DebugCollisionPolygon or node is DebugRayCast:
					node.refresh()
					node.notify_property_list_changed()
