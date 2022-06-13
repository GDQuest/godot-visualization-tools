extends Control

var _button_left_pressed := false


func _ready() -> void:
	$ButtonDebugShapes.connect("pressed", self, "_on_ButtonDebugShapes_pressed")
	$ButtonDebugNavigation.connect("pressed", self, "_on_ButtonDebugNavigation_pressed")


func _on_ButtonDebugShapes_pressed() -> void:
	GDQuestVisualizationTools.is_debug_collision_visible = not GDQuestVisualizationTools.is_debug_collision_visible


func _on_ButtonDebugNavigation_pressed() -> void:
	GDQuestVisualizationTools.is_debug_navigation_visible = not GDQuestVisualizationTools.is_debug_navigation_visible


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		_button_left_pressed = event.pressed

	elif event is InputEventMouseMotion and _button_left_pressed:
		$DebugRayCast2D.cast_to = $DebugRayCast2D.transform.xform_inv(event.position)
