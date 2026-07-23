extends StaticBody2D

@export var ingredient_type: Ingredient.Type = Ingredient.Type.YELLOW

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	visual.polygon = Ingredient.polygon_points(ingredient_type, 22.0)
	visual.color = Ingredient.COLORS[0]


func interact(player: Node) -> void:
	if not player.is_holding:
		player.set_held_item(ingredient_type, false)
