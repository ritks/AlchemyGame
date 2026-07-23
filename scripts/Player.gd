extends CharacterBody2D

const SPEED := 300.0
const INTERACT_OFFSET := 48.0
const FACING_INDICATOR_OFFSET := 30.0

var facing_dir: Vector2 = Vector2.DOWN

var is_holding: bool = false
var held_item_type: Ingredient.Type = Ingredient.Type.TRIANGLE
var held_item_cooked: bool = false

@onready var interact_area: Area2D = $InteractArea
@onready var facing_indicator: Node2D = $FacingIndicator
@onready var held_item_visual: Polygon2D = $HeldItemVisual


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
		held_item_visual.polygon = Ingredient.polygon_points(held_item_type, 16.0)
		var base_color: Color = Ingredient.COLORS[held_item_type]
		held_item_visual.color = base_color.lightened(0.4) if held_item_cooked else base_color
