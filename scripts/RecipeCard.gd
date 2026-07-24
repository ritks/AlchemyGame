extends Sprite2D

const PEEK_AMOUNT := 36.0
const SLIDE_DURATION := 0.3

var rest_position: Vector2
var hidden_position: Vector2
var is_showing: bool = false
var slide_tween: Tween


func _ready() -> void:
	rest_position = position
	var half_height: float = (texture.get_size().y * scale.y) / 2.0
	var viewport_height: float = get_viewport_rect().size.y
	hidden_position = Vector2(rest_position.x, viewport_height - PEEK_AMOUNT + half_height)
	position = hidden_position


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_recipe"):
		is_showing = not is_showing
		_animate_to(rest_position if is_showing else hidden_position)


func _animate_to(target: Vector2) -> void:
	if slide_tween:
		slide_tween.kill()
	slide_tween = create_tween()
	slide_tween.set_trans(Tween.TRANS_QUAD)
	slide_tween.set_ease(Tween.EASE_OUT)
	slide_tween.tween_property(self, "position", target, SLIDE_DURATION)
