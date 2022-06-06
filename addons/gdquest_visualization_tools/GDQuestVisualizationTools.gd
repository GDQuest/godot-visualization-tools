extends Node


func update_debug() -> void:
	var queue_stack := [get_tree().current_scene]
	while not queue_stack.empty():
		var node: Node = queue_stack.pop_back()
		if is_instance_valid(node):
			queue_stack.append_array(node.get_children())
			node.has_method("update") and node.update()
