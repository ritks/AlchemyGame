extends StaticBody2D

enum State { EMPTY, COOKING, READY, SPOILED }
enum Station { CAULDRON, MORTAR, PAN }

@export var cook_time_sec: float = 8.0
@export var spoil_time_sec: float = 6.0
@export var max_ingredients: int = 1
@export var cook_station_type: Station = Station.CAULDRON

var current_ingredients: int = 0
var ingredients_used: Array[Ingredient.Type] = []

const COLOR_EMPTY := Color(0.55, 0.55, 0.55)
const COLOR_COOKING := Color(0.9, 0.6, 0.1)
const COLOR_READY := Color(0.2, 0.8, 0.3)
const COLOR_SPOILED := Color(0.35, 0.12, 0.1)
const COLOR_BAR_COOKING := Color(0.9, 0.6, 0.1)
const COLOR_BAR_SPOIL_WARNING := Color(0.9, 0.15, 0.15)
const BAR_WIDTH := 80.0
const FEEDBACK_DURATION := 1.5

var state: State = State.EMPTY
var cooking_item_type: Ingredient.Type = Ingredient.Type.YELLOW
var showing_feedback: bool = false

@onready var body: Sprite2D = $Body
@onready var cook_timer: Timer = $CookTimer
@onready var spoil_timer: Timer = $SpoilTimer
@onready var feedback_timer: Timer = $FeedbackTimer
@onready var timer_display: Node2D = $TimerDisplay
@onready var bar_background: ColorRect = $TimerDisplay/BarBackground
@onready var bar_fill: ColorRect = $TimerDisplay/BarFill
@onready var time_label: Label = $TimerDisplay/TimeLabel


func _ready() -> void:
	if cook_station_type == Station.CAULDRON:
		pass
	if cook_station_type == Station.PAN:
		body.texture = load("res://sprites/pan.png")
	if cook_station_type == Station.MORTAR:
		body.texture = load("res://sprites/mortar.png")
		
	cook_timer.one_shot = true
	cook_timer.wait_time = cook_time_sec
	spoil_timer.one_shot = true
	spoil_timer.wait_time = spoil_time_sec
	feedback_timer.one_shot = true
	cook_timer.timeout.connect(_on_cook_timeout)
	spoil_timer.timeout.connect(_on_spoil_timeout)
	feedback_timer.timeout.connect(_on_feedback_timeout)
	_set_state(State.EMPTY)


func _process(_delta: float) -> void:
	if showing_feedback:
		return
	match state:
		State.COOKING:
			timer_display.visible = true
			bar_fill.color = COLOR_BAR_COOKING
			_update_timer_display(cook_timer.time_left, cook_time_sec)
		State.READY:
			timer_display.visible = true
			bar_fill.color = COLOR_BAR_SPOIL_WARNING
			_update_timer_display(spoil_timer.time_left, spoil_time_sec)
		_:
			timer_display.visible = false


func _update_timer_display(time_left: float, total_time: float) -> void:
	var frac: float = clampf(time_left / total_time, 0.0, 1.0)
	bar_fill.size.x = BAR_WIDTH * frac
	time_label.text = "%.2f" % time_left


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
					if cook_station_type == Station.PAN and cooking_item_type == Ingredient.Type.YELLOW:
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
		State.COOKING:
			pass  # uninterruptible
		State.READY:
			if not player.is_holding:
				var feedback: String = _get_pickup_feedback()
				player.set_held_item(cooking_item_type, true)
				spoil_timer.stop()
				_set_state(State.EMPTY)
				_show_feedback(feedback)
		State.SPOILED:
			_set_state(State.EMPTY)


func _get_pickup_feedback() -> String:
	var elapsed: float = spoil_time_sec - spoil_timer.time_left
	if elapsed <= 3.0:
		return "Great!"
	elif spoil_timer.time_left <= 5.0:
		return "OK"
	return ""


func _show_feedback(text: String) -> void:
	if text == "":
		return
	showing_feedback = true
	timer_display.visible = true
	bar_background.visible = false
	bar_fill.visible = false
	time_label.text = text
	feedback_timer.start(FEEDBACK_DURATION)


func _on_feedback_timeout() -> void:
	showing_feedback = false
	bar_background.visible = true
	bar_fill.visible = true


func _on_cook_timeout() -> void:
	_set_state(State.READY)
	spoil_timer.start()


func _on_spoil_timeout() -> void:
	_set_state(State.SPOILED)


func _set_state(new_state: State) -> void:
	if showing_feedback:
		showing_feedback = false
		feedback_timer.stop()
		bar_background.visible = true
		bar_fill.visible = true
	state = new_state
	match state:
		State.EMPTY: body.modulate = Color.WHITE
		State.COOKING: body.modulate = Color.WHITE
		State.READY: body.modulate = Color.WHITE
		State.SPOILED: body.modulate = Color.WHITE
