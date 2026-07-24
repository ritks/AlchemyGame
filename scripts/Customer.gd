extends Node2D

@onready var customer_sprite: Sprite2D = $Sprite
@onready var drink: Sprite2D = $Textbubble/Drink
@onready var drink_type: int = randi_range(9, 12)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# customer_sprite = load(res://sprites/customer.png)
	if drink_type == 9:
		drink.texture = load("res://sprites/sun_tea.png")
	elif drink_type == 10:
		drink.texture = load("res://sprites/mint_soda.png")
	elif drink_type == 11:
		drink.texture = load("res://sprites/earth_brew.png")
	elif drink_type == 12:
		drink.texture = load("res://sprites/sus_concoc.png")


func interact(player: Node) -> void:
	if player.is_holding and player.held_item_type == drink_type:
		player.clear_held_item()
		self.queue_free()
