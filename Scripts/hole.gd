extends Node2D

signal swallowed

@export var follow_speed := 18.0
@export var hole_radius := 48.0  # match your CircleShape2D radius

func _physics_process(delta: float) -> void:
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return

	var target := get_global_mouse_position()
	global_position = global_position.lerp(target, 1.0 - exp(-follow_speed * delta))

func _on_swallow_area_body_entered(body: Node) -> void:
	if not body.is_in_group("swalloable"):
		return

	if body is Node2D:
		var size := 999999.0

		var cs := body.get_node_or_null("CollisionShape2D")
		if cs and cs.shape is CircleShape2D:
			size = (cs.shape as CircleShape2D).radius * (body as Node2D).scale.x

		if size <= hole_radius:
			emit_signal("swallowed")
			body.queue_free()
