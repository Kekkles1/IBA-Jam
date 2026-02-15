extends CharacterBody2D

# Sends eaten object's radius (after scale) to the Level
signal swallowed(eaten_r: float)

# NEW: emitted when a milk item is attempted but rejected
signal lactose_rejected

@export var can_swallow_milk: bool = false
@export var follow_speed: float = 18.0
@export var max_speed: float = 2200.0

# Growth settings
@export var grow_per_swallow: float = 0.06      # +6% scale each swallow (base)
@export var grow_by_eaten_ratio: float = 0.25   # extra growth based on eaten size (0..1)
@export var max_scale: float = 4.0              # cap so it doesn't get insane
@export var grow_tween_time: float = 0.12       # seconds

@onready var swallow_cs: CollisionShape2D = $SwallowArea/CollisionShape2D

# SFX players (RejectSFX / TooBigSFX are optional)
@onready var swallow_sfx: AudioStreamPlayer2D = $SwallowSFX
@onready var reject_sfx: AudioStreamPlayer2D = get_node_or_null("RejectSFX") as AudioStreamPlayer2D
@onready var too_big_sfx: AudioStreamPlayer2D = get_node_or_null("TooBigSFX") as AudioStreamPlayer2D

func _ready() -> void:
	if swallow_sfx:
		swallow_sfx.volume_db = 15

	if reject_sfx:
		reject_sfx.volume_db = 6

	if too_big_sfx:
		too_big_sfx.volume_db = 3

func _physics_process(delta: float) -> void:
	# Collision-safe movement (TileMap can block CharacterBody2D)
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2 = get_global_mouse_position()
	var to_target: Vector2 = target - global_position

	# Smooth-ish chase but still collision aware
	var desired: Vector2 = to_target * follow_speed
	if desired.length() > max_speed:
		desired = desired.normalized() * max_speed

	velocity = desired
	move_and_slide()

func _on_swallow_area_body_entered(body: Node) -> void:
	# Only swallow things in the swalloable group
	if not body.is_in_group("swalloable"):
		return
	if not (body is Node2D):
		return

	# Milk rule (safe even if the variable doesn't exist on some objects)
	var milk_val: Variant = body.get("contains_milk") # null if missing
	if milk_val != null and bool(milk_val) and not can_swallow_milk:
		print("lactose intolerant")
		_play_sfx(reject_sfx, 0.95, 1.05)  # optional reject sound

		# NEW: tell the level that lactose was attempted
		lactose_rejected.emit()
		return

	# Get hole radius (circle radius * scale)
	var hole_r: float = _get_circle_radius(swallow_cs, self)
	if hole_r < 0.0:
		return

	# Get body radius (circle radius * scale)
	var body_node: Node2D = body as Node2D
	var body_cs: CollisionShape2D = body_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	var body_r: float = _get_circle_radius(body_cs, body_node)
	if body_r < 0.0:
		return

	# Only swallow if body is smaller OR exact same size
	if body_r <= hole_r:
		# SFX: swallow (only when actually swallowed)
		_play_sfx(swallow_sfx, 0.95, 1.10)

		# IMPORTANT: emit eaten radius for size-based progress
		swallowed.emit(body_r)
		print("swallowed (r=", body_r, ")")

		_grow_after_swallow(body_r, hole_r)

		body_node.queue_free()
	else:
		print("tooo big")
		_play_sfx(too_big_sfx, 0.90, 1.00) # optional "too big" sound

func _play_sfx(player: AudioStreamPlayer2D, pitch_min: float, pitch_max: float) -> void:
	if player == null:
		return

	# prevent machine-gun overlap
	if player.playing:
		player.stop()

	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()

# Optional helper (Level2 will call it) - safe even if reject_sfx is missing
func wait_for_reject_sfx() -> void:
	if reject_sfx == null:
		return
	if reject_sfx.playing:
		await reject_sfx.finished

func _grow_after_swallow(eaten_r: float, hole_r: float) -> void:
	# How "big" was the eaten object relative to the hole (0..1)
	var ratio: float = clamp(eaten_r / max(hole_r, 0.001), 0.0, 1.0)

	# Total growth this swallow
	var growth: float = grow_per_swallow + (ratio * grow_by_eaten_ratio)

	var current: Vector2 = scale
	var target_s: float = min(max_scale, current.x * (1.0 + growth)) # uniform scale
	var target: Vector2 = Vector2(target_s, target_s)

	# Smooth scale animation
	var t := create_tween()
	t.tween_property(self, "scale", target, grow_tween_time) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

func _get_circle_radius(cs: CollisionShape2D, owner_node: Node2D) -> float:
	if cs == null:
		return -1.0
	var shape: Shape2D = cs.shape
	if shape is CircleShape2D:
		var r: float = (shape as CircleShape2D).radius
		var s: float = max(owner_node.global_scale.x, owner_node.global_scale.y)
		return r * s
	return -1.0
