extends Control


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		get_tree().change_scene_to_file("res://scenes/Kitchen.tscn")
