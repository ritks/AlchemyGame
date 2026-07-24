extends Node2D

var remaining_customers: int = 0


func _ready() -> void:
	for child in get_children():
		if child.has_signal("order_fulfilled"):
			remaining_customers += 1
			child.order_fulfilled.connect(_on_order_fulfilled)


func _on_order_fulfilled() -> void:
	remaining_customers -= 1
	if remaining_customers <= 0:
		get_tree().change_scene_to_file("res://scenes/EndCard.tscn")
