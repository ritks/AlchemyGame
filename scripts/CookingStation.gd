extends StaticBody2D

enum State { EMPTY, COOKING, READY}
enum Station { CAULDRON, MORTAR, PAN, TRASH_CAN, STORAGE }

@export var cook_time_sec: float = 8.0
@export var max_ingredients: int = 1
@export var cook_station_type: Station = Station.CAULDRON

var current_ingredients: int = 0
var ingredients_used: Array[Ingredient.Type] = []

const FEEDBACK_DURATION := 1.5
const SUN_TEA_PERFECT_WINDOW := 2.0
const OTHER_DRINK_PERFECT_WINDOW := 3.0
const CUE_DELAY_MIN := 3.0
const CUE_DELAY_MAX := 5.0

var state: State = State.EMPTY
var cooking_item_type: Ingredient.Type = Ingredient.Type.YELLOW
var showing_feedback: bool = false

@onready var body: Sprite2D = $Body
@onready var cook_timer: Timer = $CookTimer
@onready var perfect_window_timer: Timer = $PerfectWindowTimer
@onready var cue_timer: Timer = $CueTimer
@onready var cue_visual: Sprite2D = $CueVisual
@onready var feedback_timer: Timer = $FeedbackTimer
@onready var timer_display: Node2D = $TimerDisplay
@onready var time_label: Label = $TimerDisplay/TimeLabel


func _ready() -> void:
	if cook_station_type == Station.TRASH_CAN:
		body.texture = load("res://sprites/trash_can.png")
	if cook_station_type == Station.STORAGE:
		body.texture = load("res://sprites/storage.png")
	if cook_station_type == Station.CAULDRON:
		body.texture = load("res://sprites/cauldron.png")
	if cook_station_type == Station.PAN:
		body.texture = load("res://sprites/pan.png")
	if cook_station_type == Station.MORTAR:
		body.texture = load("res://sprites/mortar.png")

	# cue_visual.texture = load("res://sprites/cue.png")

	cook_timer.one_shot = true
	cook_timer.wait_time = cook_time_sec
	perfect_window_timer.one_shot = true
	cue_timer.one_shot = true
	feedback_timer.one_shot = true
	cook_timer.timeout.connect(_on_cook_timeout)
	cue_timer.timeout.connect(_on_cue_timeout)
	feedback_timer.timeout.connect(_on_feedback_timeout)
	_set_state(State.EMPTY)


func interact(player: Node) -> void:
	match state:
		State.EMPTY:
			if player.is_holding and current_ingredients < max_ingredients:
				cooking_item_type = player.held_item_type
				ingredients_used.append(player.held_item_type)
				player.clear_held_item()
				current_ingredients += 1
				print(ingredients_used)
				if current_ingredients == max_ingredients:
					_set_state(State.COOKING)
					cook_timer.start()
					if cook_station_type == Station.STORAGE:
						_set_state(State.READY)
						cook_timer.stop()
					elif cook_station_type == Station.PAN and cooking_item_type == Ingredient.Type.YELLOW:
						cooking_item_type = Ingredient.Type.COOK_YELLOW
					elif cook_station_type == Station.PAN and cooking_item_type == Ingredient.Type.ORANGE:
						cooking_item_type = Ingredient.Type.COOK_ORANGE
					elif cook_station_type == Station.PAN and cooking_item_type == Ingredient.Type.BLUE:
						cooking_item_type = Ingredient.Type.COOK_BLUE
					elif cook_station_type == Station.MORTAR and cooking_item_type == Ingredient.Type.YELLOW:
						cooking_item_type = Ingredient.Type.GRIND_YELLOW
					elif cook_station_type == Station.MORTAR and cooking_item_type == Ingredient.Type.ORANGE:
						cooking_item_type = Ingredient.Type.GRIND_ORANGE
					elif cook_station_type == Station.MORTAR and cooking_item_type == Ingredient.Type.BLUE:
						cooking_item_type = Ingredient.Type.GRIND_BLUE
					elif cook_station_type == Station.CAULDRON and Ingredient.Type.GRIND_YELLOW in ingredients_used and Ingredient.Type.COOK_ORANGE in ingredients_used:
						cooking_item_type = Ingredient.Type.SUN_TEA
					elif cook_station_type == Station.CAULDRON and Ingredient.Type.GRIND_BLUE in ingredients_used and Ingredient.Type.COOK_BLUE in ingredients_used:
						cooking_item_type = Ingredient.Type.MINT_SODA
					elif cook_station_type == Station.CAULDRON and Ingredient.Type.GRIND_ORANGE in ingredients_used and Ingredient.Type.GRIND_ORANGE in ingredients_used:
						cooking_item_type = Ingredient.Type.EARTH_BREW
					elif cook_station_type == Station.CAULDRON and Ingredient.Type.EARTH_BREW in ingredients_used and Ingredient.Type.COOK_BLUE in ingredients_used:
						cooking_item_type = Ingredient.Type.SUS_CONCOC
					else:
						cooking_item_type = Ingredient.Type.TRASH
					print(cooking_item_type)
					current_ingredients = 0
					ingredients_used = []
					if _has_mid_cook_cue(cooking_item_type):
						cue_visual.visible = false
						cue_timer.start(randf_range(CUE_DELAY_MIN, CUE_DELAY_MAX))
		State.COOKING:
			pass  # uninterruptible
		State.READY:
			if not player.is_holding:
				var feedback: String = ""
				if _is_cauldron_drink(cooking_item_type):
					feedback = "Perfect!" if not perfect_window_timer.is_stopped() else "Good"
				player.set_held_item(cooking_item_type, true)
				perfect_window_timer.stop()
				cue_timer.stop()
				cue_visual.visible = false
				_set_state(State.EMPTY)
				_show_feedback(feedback)


func _is_cauldron_drink(type: Ingredient.Type) -> bool:
	return type == Ingredient.Type.SUN_TEA or type == Ingredient.Type.MINT_SODA \
		or type == Ingredient.Type.EARTH_BREW or type == Ingredient.Type.SUS_CONCOC


func _has_mid_cook_cue(type: Ingredient.Type) -> bool:
	return type == Ingredient.Type.MINT_SODA or type == Ingredient.Type.EARTH_BREW \
		or type == Ingredient.Type.SUS_CONCOC


func _perfect_window_for(type: Ingredient.Type) -> float:
	if type == Ingredient.Type.SUN_TEA:
		return SUN_TEA_PERFECT_WINDOW
	return OTHER_DRINK_PERFECT_WINDOW


func _show_feedback(text: String) -> void:
	if text == "":
		return
	showing_feedback = true
	timer_display.visible = true
	time_label.text = text
	feedback_timer.start(FEEDBACK_DURATION)


func _on_feedback_timeout() -> void:
	showing_feedback = false
	timer_display.visible = false


func _on_cook_timeout() -> void:
	_set_state(State.READY)
	if _is_cauldron_drink(cooking_item_type):
		perfect_window_timer.start(_perfect_window_for(cooking_item_type))


func _on_cue_timeout() -> void:
	cue_visual.visible = true


func _set_state(new_state: State) -> void:
	if showing_feedback:
		showing_feedback = false
		feedback_timer.stop()
		timer_display.visible = false
	state = new_state
	match state:
		State.EMPTY: body.modulate = Color.WHITE
		State.COOKING: body.modulate = Color.WHITE
		State.READY: body.modulate = Color.WHITE
