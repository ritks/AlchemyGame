extends CharacterBody2D

const SPEED := 300.0
const INTERACT_OFFSET := 48.0
const FACING_INDICATOR_OFFSET := 30.0

var facing_dir: Vector2 = Vector2.DOWN

@onready var interact_area: Area2D = $InteractArea
@onready var facing_indicator: Node2D = $FacingIndicator


func _ready() -> void:
	_update_facing_transforms()


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
		print("interact pressed | facing=%s | overlaps=%s" % [facing_dir, interact_area.get_overlapping_areas()])


func _update_facing_transforms() -> void:
	interact_area.position = facing_dir * INTERACT_OFFSET
	interact_area.rotation = facing_dir.angle()
	facing_indicator.position = facing_dir * FACING_INDICATOR_OFFSET
	facing_indicator.rotation = facing_dir.angle()
