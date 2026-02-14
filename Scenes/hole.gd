extends Node2D

@export var follow_speed := 18.0  # bigger = snappier

func _physics_process(delta: float) -> void:
	var target := get_global_mouse_position()
	# smooth follow
	global_position = global_position.lerp(target, 1.0 - exp(-follow_speed * delta))
