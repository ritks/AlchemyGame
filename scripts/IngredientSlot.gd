extends StaticBody2D

@export var ingredient_type: Ingredient.Type = Ingredient.Type.YELLOW

@onready var visual: Polygon2D = $Visual
@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	if ingredient_type == Ingredient.Type.YELLOW:
		sprite.texture = load("res://sprites/yellow.png")
	elif ingredient_type == Ingredient.Type.ORANGE:
		sprite.texture = load("res://sprites/orange.png")
	elif ingredient_type == Ingredient.Type.BLUE:
		sprite.texture = load("res://sprites/blue.png")
	# visual.polygon = Ingredient.polygon_points(ingredient_type, 22.0)
	# visual.color = Ingredient.COLORS[0]


func interact(player: Node) -> void:
	if not player.is_holding:
		player.set_held_item(ingredient_type, false)
