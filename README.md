# Godot Visualization Tools

A collection of scripts and tools for debug visualizations and animations for content creation.

This is a work-in-progress. Mose of this code comes from our project [Godot Node Essentials](https://github.com/GDQuest/godot-node-essentials).

## Debug drawing

Most of the `DebugDraw` classes in the `debug_drawing` directory work just by adding them as a child of a given node.

For example, to visualize a 3D RayCast, add a DebugDrawRayCast node as a child of it.

All debug drawing nodes belong to a group named `DebugDrawing`, making it easy to toggle their visibility:

``` gdscript
# Show all debug shapes (default)
get_tree().call_group("DebugDrawing", "show")
# Hide all debug shapes
get_tree().call_group("DebugDrawing", "hide")
```

You can automate the generation of debug shapes with some code. Here's how we do it in Godot Node Essentials, using several groups for different color codes:

``` gdscript
func _create_debug_drawing_nodes() -> void:
	for node in get_tree().get_nodes_in_group("Draw"):
		# There are cases we manually added or need to manually add debug
		# drawing nodes rather than generate them.
		if has_debug_draw_child(node):
			continue

		var instance = null
		var is_collision_shape := false

		if node is CollisionShape2D:
			instance = DebugDrawCollisionShape2D.new()
			is_collision_shape = true
		elif node is CollisionShape:
			instance = DebugDrawCollisionShape.new()
			is_collision_shape = true
		elif node is RayCast:
			instance = DebugDrawRayCast.new()
		elif node is RayCast2D:
			instance = DebugDrawRayCast2D.new()
		elif node is Path:
			instance = DebugDrawPath.new()
		elif node is Path2D:
			instance = DebugDrawPath2D.new()
		else:
			print_debug("Can't draw debug collision for %s." % [node.get_class()])
			continue

		if is_collision_shape:
			for group in node.get_groups():
				if group in NodeEssentialsPalette.DEBUG_DRAWING_GROUPS:
					instance.color = NodeEssentialsPalette.COLORS_MAP[group]
					break

		node.add_child(instance)
		instance.visible = areas_visible
```
