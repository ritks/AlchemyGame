extends StaticBody2D

enum State { EMPTY, COOKING, READY}
enum Station { CAULDRON, MORTAR, PAN, TRASH_CAN, STORAGE }

@export var cook_time_sec: float = 8.0
@export var max_ingredients: int = 1
@export var cook_station_type: Station = Station.CAULDRON

var current_ingredients: int = 0
var ingredients_used: Array[Ingredient.Type] = []

const FEEDBACK_DURATION := 1.5
const CAULDRON_LOCKOUT_SEC := 3.0
const CUE_DELAY_MIN := 3.0
const CUE_DELAY_MAX := 5.0
const WINDOW_HALF_WIDTH := 1
const DRINK_TARGET_SEC := {
	Ingredient.Type.SUN_TEA: 5.0,
	Ingredient.Type.MINT_SODA: 6.0,
	Ingredient.Type.EARTH_BREW: 7.0,
	Ingredient.Type.SUS_CONCOC: 8.0,
}
const READY_ICON_OFFSET := {
	Station.MORTAR: Vector2(-80, 0),
	Station.PAN: Vector2(80, 0),
	Station.CAULDRON: Vector2(90, -90),
	Station.STORAGE: Vector2(80, 0),
	Station.TRASH_CAN: Vector2(80, 0),
}

var state: State = State.EMPTY
var cooking_item_type: Ingredient.Type = Ingredient.Type.YELLOW
var showing_feedback: bool = false
var cue_started_at_msec: int = 0
var nearby_player: Node = null

@onready var body: Sprite2D = $Body
@onready var interact_area: Area2D = $InteractArea
@onready var cook_timer: Timer = $CookTimer
@onready var cue_timer: Timer = $CueTimer
@onready var cue_visual: Sprite2D = $CueVisual
@onready var feedback_timer: Timer = $FeedbackTimer
@onready var timer_display: Node2D = $TimerDisplay
@onready var time_label: Label = $TimerDisplay/TimeLabel
@onready var ready_icon: Sprite2D = $ReadyIcon
@onready var ready_icon_item: Sprite2D = $ReadyIcon/ReadyIconItem


func _ready() -> void:
	if cook_station_type == Station.TRASH_CAN:
		body.texture = load("res://sprites/trash_can.png")
	elif cook_station_type == Station.STORAGE:
		body.texture = load("res://sprites/storage.png")
	elif cook_station_type == Station.CAULDRON:
		body.texture = load("res://sprites/cauldron.png")
	elif cook_station_type == Station.PAN:
		body.texture = load("res://sprites/pan.png")
	elif cook_station_type == Station.MORTAR:
		body.texture = load("res://sprites/mortar.png")

	# cue_visual.texture = load("res://sprites/cue.png")

	# Trash Can and Storage don't get ready-icon previews/reveals at all, so skip
	# _process() entirely for them rather than early-returning out of it every frame.
	if cook_station_type == Station.TRASH_CAN or cook_station_type == Station.STORAGE:
		set_process(false)
	else:
		ready_icon.texture = load("res://sprites/ready_icon.png")
		ready_icon.position = READY_ICON_OFFSET[cook_station_type]
		ready_icon.flip_h = cook_station_type == Station.PAN or cook_station_type == Station.CAULDRON

	cook_timer.one_shot = true
	cook_timer.wait_time = cook_time_sec
	cue_timer.one_shot = true
	feedback_timer.one_shot = true
	cook_timer.timeout.connect(_on_cook_timeout)
	cue_timer.timeout.connect(_on_cue_timeout)
	feedback_timer.timeout.connect(_on_feedback_timeout)
	interact_area.body_entered.connect(_on_interact_area_body_entered)
	interact_area.body_exited.connect(_on_interact_area_body_exited)
	_set_state(State.EMPTY)


func _process(_delta: float) -> void:
	_update_ready_icon_preview()


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
					if cook_station_type == Station.STORAGE:
						cooking_item_type = _predict_single_result(cooking_item_type)
						_set_state(State.READY)
						_update_item_visual(Ingredient.sprite_texture(cooking_item_type))
					elif cook_station_type == Station.CAULDRON:
						cooking_item_type = _predict_cauldron_result(ingredients_used)
						print(cooking_item_type)
						_set_state(State.COOKING)
						# Flat lockout before the cue timer even starts counting down, so the
						# player can never grab a cauldron drink immediately after placing it.
						cook_timer.start(CAULDRON_LOCKOUT_SEC)
					else:
						cooking_item_type = _predict_single_result(cooking_item_type)
						print(cooking_item_type)
						_set_state(State.COOKING)
						cook_timer.start()
					current_ingredients = 0
					ingredients_used = []
		State.COOKING:
			pass  # uninterruptible
		State.READY:
			if not player.is_holding:
				var feedback: String = ""
				var final_item: Ingredient.Type = cooking_item_type
				if cook_station_type == Station.CAULDRON:
					var result: Dictionary = _grade_cauldron_pickup()
					final_item = result["item"]
					feedback = result["feedback"]
				player.set_held_item(final_item, true)
				cue_timer.stop()
				cue_visual.visible = false
				_update_item_visual(null)
				_set_state(State.EMPTY)
				_show_feedback(feedback)


func _on_interact_area_body_entered(body_node: Node) -> void:
	nearby_player = body_node


func _on_interact_area_body_exited(body_node: Node) -> void:
	if body_node == nearby_player:
		nearby_player = null


func _predict_single_result(input_type: Ingredient.Type) -> Ingredient.Type:
	if cook_station_type == Station.STORAGE:
		return input_type
	elif cook_station_type == Station.PAN:
		if input_type == Ingredient.Type.YELLOW:
			return Ingredient.Type.COOK_YELLOW
		elif input_type == Ingredient.Type.ORANGE:
			return Ingredient.Type.COOK_ORANGE
		elif input_type == Ingredient.Type.BLUE:
			return Ingredient.Type.COOK_BLUE
	elif cook_station_type == Station.MORTAR:
		if input_type == Ingredient.Type.YELLOW:
			return Ingredient.Type.GRIND_YELLOW
		elif input_type == Ingredient.Type.ORANGE:
			return Ingredient.Type.GRIND_ORANGE
		elif input_type == Ingredient.Type.BLUE:
			return Ingredient.Type.GRIND_BLUE
	return Ingredient.Type.TRASH


func _predict_cauldron_result(ingredients: Array[Ingredient.Type]) -> Ingredient.Type:
	if Ingredient.Type.GRIND_YELLOW in ingredients and Ingredient.Type.COOK_ORANGE in ingredients:
		return Ingredient.Type.SUN_TEA
	elif Ingredient.Type.GRIND_BLUE in ingredients and Ingredient.Type.COOK_BLUE in ingredients:
		return Ingredient.Type.MINT_SODA
	elif Ingredient.Type.GRIND_ORANGE in ingredients and Ingredient.Type.GRIND_ORANGE in ingredients:
		return Ingredient.Type.EARTH_BREW
	elif Ingredient.Type.EARTH_BREW in ingredients and Ingredient.Type.COOK_BLUE in ingredients:
		return Ingredient.Type.SUS_CONCOC
	return Ingredient.Type.TRASH


func _update_ready_icon_preview() -> void:
	if state != State.EMPTY:
		return
	if cook_station_type == Station.CAULDRON:
		if current_ingredients == 1 and nearby_player and nearby_player.is_holding:
			var hypothetical: Array[Ingredient.Type] = ingredients_used.duplicate()
			hypothetical.append(nearby_player.held_item_type)
			var predicted: Ingredient.Type = _predict_cauldron_result(hypothetical)
			_show_ready_icon(predicted)
		else:
			_hide_ready_icon()
	else:
		if current_ingredients < max_ingredients and nearby_player and nearby_player.is_holding:
			var predicted: Ingredient.Type = _predict_single_result(nearby_player.held_item_type)
			_show_ready_icon(predicted)
		else:
			_hide_ready_icon()


func _show_ready_icon(result: Ingredient.Type) -> void:
	ready_icon.visible = true
	ready_icon_item.texture = Ingredient.sprite_texture(result)


func _hide_ready_icon() -> void:
	ready_icon.visible = false


func _update_item_visual(texture: Texture2D) -> void:
	var item_visual: Sprite2D = get_node_or_null("Item")
	if item_visual:
		item_visual.texture = texture


func _is_cauldron_drink(type: Ingredient.Type) -> bool:
	return type == Ingredient.Type.SUN_TEA or type == Ingredient.Type.MINT_SODA \
		or type == Ingredient.Type.EARTH_BREW or type == Ingredient.Type.SUS_CONCOC


func _grade_cauldron_pickup() -> Dictionary:
	if not _is_cauldron_drink(cooking_item_type):
		return {"item": Ingredient.Type.TRASH, "feedback": "Trash!"}
	var elapsed_sec: float = (Time.get_ticks_msec() - cue_started_at_msec) / 1000.0
	var target: float = DRINK_TARGET_SEC[cooking_item_type]
	if absf(elapsed_sec - target) <= WINDOW_HALF_WIDTH:
		return {"item": cooking_item_type, "feedback": "Perfect!"}
	return {"item": Ingredient.Type.TRASH, "feedback": "Trash!"}


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
	if cook_station_type == Station.CAULDRON:
		cue_timer.start(randf_range(CUE_DELAY_MIN, CUE_DELAY_MAX))
	else:
		_set_state(State.READY)


func _on_cue_timeout() -> void:
	cue_visual.visible = true
	cue_started_at_msec = Time.get_ticks_msec()
	_set_state(State.READY)


func _set_state(new_state: State) -> void:
	if showing_feedback:
		showing_feedback = false
		feedback_timer.stop()
		timer_display.visible = false
	state = new_state
	match state:
		State.EMPTY:
			body.modulate = Color.WHITE
			_hide_ready_icon()
		State.COOKING:
			body.modulate = Color.WHITE
			_hide_ready_icon()
		State.READY:
			body.modulate = Color.WHITE
			if cook_station_type == Station.MORTAR or cook_station_type == Station.PAN:
				_show_ready_icon(cooking_item_type)
