extends Control

@onready var button_debug_shapes := $HBoxContainer/ButtonDebugShapes
@onready var button_debug_navigation := $HBoxContainer/ButtonDebugNavigation


func _ready() -> void:
	button_debug_shapes.connect("pressed",Callable(self,"_on_ButtonDebugShapes_pressed"))
	button_debug_navigation.connect("pressed",Callable(self,"_on_ButtonDebugNavigation_pressed"))


func _on_ButtonDebugShapes_pressed() -> void:
	GDQuestVisualizationTools.is_debug_collision_visible = not GDQuestVisualizationTools.is_debug_collision_visible


func _on_ButtonDebugNavigation_pressed() -> void:
	GDQuestVisualizationTools.is_debug_navigation_visible = not GDQuestVisualizationTools.is_debug_navigation_visible
