extends StaticBody2D

enum State { EMPTY, COOKING, READY, SPOILED }

@export var cook_time_sec: float = 10.0
@export var spoil_time_sec: float = 8.0

const COLOR_EMPTY := Color(0.55, 0.55, 0.55)
const COLOR_COOKING := Color(0.9, 0.6, 0.1)
const COLOR_READY := Color(0.2, 0.8, 0.3)
const COLOR_SPOILED := Color(0.35, 0.12, 0.1)
const COLOR_BAR_COOKING := Color(0.9, 0.6, 0.1)
const COLOR_BAR_SPOIL_WARNING := Color(0.9, 0.15, 0.15)
const BAR_WIDTH := 80.0

var state: State = State.EMPTY

@onready var body: Polygon2D = $Body
@onready var cook_timer: Timer = $CookTimer
@onready var spoil_timer: Timer = $SpoilTimer
@onready var timer_display: Node2D = $TimerDisplay
@onready var bar_fill: ColorRect = $TimerDisplay/BarFill
@onready var time_label: Label = $TimerDisplay/TimeLabel


func _ready() -> void:
	body.polygon = _circle_points(36.0)
	cook_timer.one_shot = true
	cook_timer.wait_time = cook_time_sec
	spoil_timer.one_shot = true
	spoil_timer.wait_time = spoil_time_sec
	cook_timer.timeout.connect(_on_cook_timeout)
	spoil_timer.timeout.connect(_on_spoil_timeout)
	_set_state(State.EMPTY)


func _process(_delta: float) -> void:
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


func interact() -> void:
	match state:
		State.EMPTY:
			_set_state(State.COOKING)
			cook_timer.start()
		State.COOKING:
			pass  # uninterruptible
		State.READY:
			print("[CookingStation] picked up")
			spoil_timer.stop()
			_set_state(State.EMPTY)
		State.SPOILED:
			print("[CookingStation] discarded spoiled item")
			_set_state(State.EMPTY)


func _on_cook_timeout() -> void:
	_set_state(State.READY)
	spoil_timer.start()


func _on_spoil_timeout() -> void:
	_set_state(State.SPOILED)


func _set_state(new_state: State) -> void:
	state = new_state
	match state:
		State.EMPTY: body.color = COLOR_EMPTY
		State.COOKING: body.color = COLOR_COOKING
		State.READY: body.color = COLOR_READY
		State.SPOILED: body.color = COLOR_SPOILED


func _circle_points(radius: float, segments: int = 24) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var angle := TAU * i / segments
		pts.append(Vector2(cos(angle), sin(angle)) * radius)
	return pts
