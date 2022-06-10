extends Node


var is_debug_collision_2d_visible := true setget set_is_debug_collision_2d_visible
var is_debug_navigation_2d_visible := true setget set_is_debug_navigation_2d_visible


func _ready() -> void:
	set_is_debug_collision_2d_visible(is_debug_collision_2d_visible)
	set_is_debug_navigation_2d_visible(is_debug_navigation_2d_visible)


func set_is_debug_collision_2d_visible(new_is_debug_collision_2d_visible: bool) -> void:
	is_debug_collision_2d_visible = new_is_debug_collision_2d_visible
	get_tree().call_group("GVTCollision2D", "set_visible", is_debug_collision_2d_visible)


func set_is_debug_navigation_2d_visible(new_is_debug_navigation_2d_visible: bool) -> void:
	is_debug_navigation_2d_visible = new_is_debug_navigation_2d_visible
	get_tree().call_group("GVTNavigation2D", "set_visible", is_debug_navigation_2d_visible)
