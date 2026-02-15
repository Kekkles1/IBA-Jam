extends CharacterBody2D

# send eaten radius + the node that got swallowed
signal swallowed(eaten_r: float, body: Node2D)

@export var can_swallow_milk: bool = false

# movement
@export var follow_speed: float = 18.0
@export var max_speed: float = 2200.0

# Level3 hook
@export var level_logic_path: NodePath

# Growth settings
@export var grow_per_swallow: float = 0.06
@export var grow_by_eaten_ratio: float = 0.25
@export var max_scale: float = 4.0
@export var grow_tween_time: float = 0.12

@onready var swallow_cs: CollisionShape2D = $SwallowArea/CollisionShape2D

func _physics_process(delta: float) -> void:
	# Collision-safe movement
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2 = get_global_mouse_position()
	var to_target: Vector2 = target - global_position

	var desired: Vector2 = to_target * follow_speed
	if desired.length() > max_speed:
		desired = desired.normalized() * max_speed

	velocity = desired
	move_and_slide()

func _on_swallow_area_body_entered(body: Node) -> void:
	if not body.is_in_group("swalloable"):
		return
	if not (body is Node2D):
		return

	var body_node: Node2D = body as Node2D

	# Milk rule (safe even if missing)
	var milk_val: Variant = body_node.get("contains_milk")
	if milk_val != null and bool(milk_val) and not can_swallow_milk:
		print("lactose intolerant")
		return

	# Size check
	var hole_r: float = _get_circle_radius(swallow_cs, self)
	if hole_r < 0.0:
		return

	var body_cs: CollisionShape2D = body_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var body_r: float = _get_circle_radius(body_cs, body_node)
	if body_r < 0.0:
		return

	if body_r > hole_r:
		print("tooo big")
		return

	# Pattern rejection hook (reject = do NOT swallow)
	var level_logic: Node = _get_level_logic()
	if level_logic != null and level_logic.has_method("try_accept_swallow"):
		var ok: bool = bool(level_logic.call("try_accept_swallow", body_node))
		if not ok:
			print("REJECTED BY PATTERN")
			return

	# Swallow
	swallowed.emit(body_r, body_node)
	print("swallowed (r=", body_r, ")")

	_grow_after_swallow(body_r, hole_r)
	body_node.queue_free()

func _get_level_logic() -> Node:
	if level_logic_path != NodePath(""):
		return get_node_or_null(level_logic_path)
	return get_parent()

func _grow_after_swallow(eaten_r: float, hole_r: float) -> void:
	var ratio: float = clamp(eaten_r / max(hole_r, 0.001), 0.0, 1.0)
	var growth: float = grow_per_swallow + (ratio * grow_by_eaten_ratio)

	var current: Vector2 = scale
	var target_s: float = min(max_scale, current.x * (1.0 + growth))
	var target: Vector2 = Vector2(target_s, target_s)

	var t := create_tween()
	t.tween_property(self, "scale", target, grow_tween_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func _get_circle_radius(cs: CollisionShape2D, owner_node: Node2D) -> float:
	if cs == null or cs.shape == null:
		return -1.0

	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		var s: float = max(owner_node.global_scale.x, owner_node.global_scale.y)
		return r * s

	return -1.0
