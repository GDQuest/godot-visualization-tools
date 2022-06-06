tool
extends EditorPlugin


func _enter_tree() -> void:
	get_editor_interface().get_inspector().connect(
		"property_edited", self, "_on_EditorInspector_property_edited"
	)
	add_autoload_singleton(
		"GDQuestVisualizationTools",
		"res://addons/gdquest_visualization_tools/GDQuestVisualizationTools.gd"
	)


func _exit_tree() -> void:
	remove_autoload_singleton("GDQuestVisualizationTools")


func _on_EditorInspector_property_edited(property: String) -> void:
	match property:
		"palette", "enabled":
			get_editor_interface().get_inspector().refresh()
