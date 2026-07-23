extends CharacterBody2D

const SPEED := 1000.0
const INTERACT_OFFSET := 48.0
const FACING_INDICATOR_OFFSET := 30.0

var facing_dir: Vector2 = Vector2.DOWN

var is_holding: bool = false
var held_item_type: Ingredient.Type = Ingredient.Type.YELLOW
var held_item_cooked: bool = false

@onready var interact_area: Area2D = $InteractArea
@onready var facing_indicator: Node2D = $FacingIndicator
@onready var held_item_visual: Sprite2D = $HeldItemVisual


func _ready() -> void:
	_update_facing_transforms()
	_update_held_item_visual()


func _physics_process(_delta: float) -> void:
	var input_dir := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		facing_dir = input_dir

	velocity = input_dir * SPEED
	move_and_slide()

	_update_facing_transforms()

	if Input.is_action_just_pressed("interact"):
		for area in interact_area.get_overlapping_areas():
			var target: Node = area.owner
			if target and target.has_method("interact"):
				target.interact(self)
				break


func _update_facing_transforms() -> void:
	interact_area.position = facing_dir * INTERACT_OFFSET
	interact_area.rotation = facing_dir.angle()
	facing_indicator.position = facing_dir * FACING_INDICATOR_OFFSET
	facing_indicator.rotation = facing_dir.angle()


func set_held_item(type: Ingredient.Type, cooked: bool) -> void:
	is_holding = true
	held_item_type = type
	held_item_cooked = cooked
	_update_held_item_visual()


func clear_held_item() -> void:
	is_holding = false
	_update_held_item_visual()


func _update_held_item_visual() -> void:
	held_item_visual.visible = is_holding
	if is_holding:
		if held_item_type == Ingredient.Type.YELLOW:
			held_item_visual.texture = load("res://sprites/yellow.png")
		elif held_item_type == Ingredient.Type.ORANGE:
			held_item_visual.texture = load("res://sprites/orange.png")
		elif held_item_type == Ingredient.Type.BLUE:
			held_item_visual.texture = load("res://sprites/blue.png")
		elif held_item_type == Ingredient.Type.COOK_YELLOW:
			held_item_visual.texture = load("res://sprites/cook_yellow.png")
		elif held_item_type == Ingredient.Type.COOK_ORANGE:
			held_item_visual.texture = load("res://sprites/cook_orange.png")
		elif held_item_type == Ingredient.Type.COOK_BLUE:
			held_item_visual.texture = load("res://sprites/cook_blue.png")
		elif held_item_type == Ingredient.Type.GRIND_YELLOW:
			held_item_visual.texture = load("res://sprites/grind_yellow.png")
		elif held_item_type == Ingredient.Type.GRIND_ORANGE:
			held_item_visual.texture = load("res://sprites/grind_orange.png")
		elif held_item_type == Ingredient.Type.GRIND_BLUE:
			held_item_visual.texture = load("res://sprites/grind_blue.png")
		elif held_item_type == Ingredient.Type.SUN_TEA:
			held_item_visual.texture = load("res://sprites/sun_tea.png")
		elif held_item_type == Ingredient.Type.MINT_SODA:
			held_item_visual.texture = load("res://sprites/mint_soda.png")
		elif held_item_type == Ingredient.Type.EARTH_BREW:
			held_item_visual.texture = load("res://sprites/earth_brew.png")
		elif held_item_type == Ingredient.Type.SUS_CONCOC:
			held_item_visual.texture = load("res://sprites/sus_concoc.png")
		else:
			held_item_visual.texture = load("res://sprites/trash.png")
