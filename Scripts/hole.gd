extends Node2D

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

	# simple "fit" check using collision bounds
	if body is Node2D:
		var size := 999999.0

		# If it has a CollisionShape2D with a CircleShape2D
		var cs := body.get_node_or_null("CollisionShape2D")
		if cs and cs.shape is CircleShape2D:
			size = (cs.shape as CircleShape2D).radius * body.scale.x

		# If it fits, swallow
		if size <= hole_radius:
			body.queue_free()
