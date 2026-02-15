extends CharacterBody2D

# send eaten radius + the node that got swallowed
signal swallowed(eaten_r: float, body: Node2D)

# SFX players (RejectSFX / TooBigSFX are optional, but you have them)
@onready var swallow_sfx: AudioStreamPlayer2D = $SwallowSFX
@onready var reject_sfx: AudioStreamPlayer2D = $RejectSFX
@onready var too_big_sfx: AudioStreamPlayer2D = $TooBigSFX

# Hole body collider (for wall collision) + swallow area collider (for detecting food)
@onready var hole_body_cs: CollisionShape2D = $CollisionShape2D
@onready var swallow_cs: CollisionShape2D = $SwallowArea/CollisionShape2D

@export var can_swallow_milk: bool = false

# movement (collision-safe)
@export var follow_speed: float = 18.0
@export var max_speed: float = 2200.0

# Level3 hook
@export var level_logic_path: NodePath

# Scene path for lactose
@export var lactose_scene_path: String = "res://Scenes/LactoseScreen2.tscn"

# Growth settings
@export var grow_per_swallow: float = 0.06
@export var grow_by_eaten_ratio: float = 0.25
@export var max_scale: float = 4.0
@export var grow_tween_time: float = 0.12

var _transitioning: bool = false
var _grow_tween: Tween

func _ready() -> void:
	if swallow_sfx:
		swallow_sfx.volume_db = 15
	if reject_sfx:
		reject_sfx.volume_db = 10
	if too_big_sfx:
		too_big_sfx.volume_db = 3

func _physics_process(delta: float) -> void:
	# Collision-safe movement (CharacterBody2D)
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
	if _transitioning:
		return
	if not (body is Node2D):
		return
	if not body.is_in_group("swalloable"):
		return

	var body_node: Node2D = body as Node2D

	# Milk rule (safe even if property missing)
	var milk_val: Variant = body_node.get("contains_milk")
	if milk_val != null and bool(milk_val) and not can_swallow_milk:
		_go_to_lactose()
		return

	# Size check: compare swallowed object's circle to hole swallow circle
	var hole_r: float = _get_circle_radius(swallow_cs, self)
	if hole_r < 0.0:
		return

	var body_cs: CollisionShape2D = body_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var body_r: float = _get_circle_radius(body_cs, body_node)
	if body_r < 0.0:
		return

	if body_r > hole_r:
		if too_big_sfx:
			too_big_sfx.play()
		return

	# Pattern rejection hook (reject = do NOT swallow)
	var level_logic: Node = _get_level_logic()
	if level_logic != null and level_logic.has_method("try_accept_swallow"):
		var ok: bool = bool(level_logic.call("try_accept_swallow", body_node))
		if not ok:
			if reject_sfx:
				reject_sfx.play()
			return

	# Swallow
	if swallow_sfx:
		swallow_sfx.play()

	swallowed.emit(body_r, body_node)
	_grow_after_swallow(body_r, hole_r)
	body_node.queue_free()

func _go_to_lactose() -> void:
	if _transitioning:
		return
	_transitioning = true
	if lactose_scene_path == null or lactose_scene_path == "":
		return
	call_deferred("_do_change_scene", lactose_scene_path)

func _do_change_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)

func _get_level_logic() -> Node:
	if level_logic_path != NodePath(""):
		return get_node_or_null(level_logic_path)
	return get_parent()

func _grow_after_swallow(eaten_r: float, hole_r: float) -> void:
	# growth amount
	var ratio: float = clamp(eaten_r / max(hole_r, 0.001), 0.0, 1.0)
	var growth: float = grow_per_swallow + (ratio * grow_by_eaten_ratio)

	# target scale (uniform)
	var current_s: float = scale.x
	var target_s: float = min(max_scale, current_s * (1.0 + growth))
	var target: Vector2 = Vector2(target_s, target_s)

	# kill previous tween so scale doesn't fight itself
	if _grow_tween != null and _grow_tween.is_running():
		_grow_tween.kill()

	_grow_tween = create_tween()
	_grow_tween.tween_property(self, "scale", target, grow_tween_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# IMPORTANT: keep both colliders in sync with the scale
	# CharacterBody2D collider scales automatically via node scale.
	# But we duplicate shapes to avoid shared-resource edits if you ever change radius.
	_dup_circle_shape_if_needed(hole_body_cs)
	_dup_circle_shape_if_needed(swallow_cs)

func _dup_circle_shape_if_needed(cs: CollisionShape2D) -> void:
	if cs == null or cs.shape == null:
		return
	# duplicate once so it's not a shared resource between instances
	if not cs.shape.resource_local_to_scene:
		cs.shape = cs.shape.duplicate(true)
		cs.shape.resource_local_to_scene = true

func _get_circle_radius(cs: CollisionShape2D, owner_node: Node2D) -> float:
	if cs == null or cs.shape == null:
		return -1.0

	if cs.shape is CircleShape2D:
		var r: float = (cs.shape as CircleShape2D).radius
		var s: float = max(owner_node.global_scale.x, owner_node.global_scale.y)
		return r * s

	return -1.0
