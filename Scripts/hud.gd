extends CanvasLayer

@export var start_seconds: float = 90.0

@onready var timer_label: Label = $Root/TimerLabel
@onready var progress_bar: Range = $Root/ProgressBar

var time_left: float

signal time_up
#use this signal as time up

func _ready() -> void:
	time_left = start_seconds
	_update_timer_label()

	# progress defaults
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0


func _process(delta: float) -> void:
	if time_left <= 0.0:
		return

	time_left -= delta

	if time_left <= 0.0:
		time_left = 0.0
		_update_timer_label()
		emit_signal("time_up")
		return

	_update_timer_label()

func _update_timer_label() -> void:
	timer_label.text = str(int(ceil(time_left)))

func reset_timer(new_seconds: float = -1.0) -> void:
	time_left = (new_seconds if new_seconds >= 0.0 else start_seconds)
	_update_timer_label()

# -----------------------------
# PROGRESS BAR (separate system)
# -----------------------------

# If you want to set progress as 0..1 (percent)
func set_progress01(p: float) -> void:
	p = clamp(p, 0.0, 1.0)

	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = p * 100.0


# If you want "current out of total" (e.g., swallowed / total)
func set_progress(current: float, total: float) -> void:
	if total <= 0.0:
		progress_bar.min_value = 0.0
		progress_bar.max_value = 1.0
		progress_bar.value = 0.0
		return

	progress_bar.min_value = 0.0
	progress_bar.max_value = total
	progress_bar.value = clamp(current, 0.0, total)
