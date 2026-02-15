extends Node2D

@onready var hole: Node = $Hole
@onready var hud: CanvasLayer = $UI_HUD

var total_safe_size: float = 0.0
var eaten_safe_size: float = 0.0
var ending := false

func _ready() -> void:
	await get_tree().process_frame

	total_safe_size = _sum_safe_sizes(self)
	eaten_safe_size = 0.0

	print("TOTAL SAFE SIZE:", total_safe_size)

	hud.set_progress01(0.0)

	# hole emits swallowed(eaten_r: float)
	hole.swallowed.connect(_on_hole_swallowed)

	# NEW: hole emits lactose_rejected when milk is attempted but blocked
	hole.lactose_rejected.connect(_on_lactose_rejected)

	hud.time_up.connect(_on_time_up)

func _on_hole_swallowed(eaten_r: float) -> void:
	if ending:
		return

	# milk items won't reach here because hole blocks them
	eaten_safe_size += eaten_r

	var p := 0.0
	if total_safe_size > 0.0:
		p = eaten_safe_size / total_safe_size

	hud.set_progress01(p)
	print("eaten_r=", eaten_r, " eaten_safe_size=", eaten_safe_size, " p=", p)

	if p >= 0.999:
		_on_progress_full()

func _on_time_up() -> void:
	if ending:
		return
	ending = true

	get_tree().change_scene_to_file("res://Scenes/TimerLossScreen2.tscn")

func _on_lactose_rejected() -> void:
	if ending:
		return
	ending = true

	# Wait for the reject sound to finish (it plays inside Hole)
	if hole.has_method("wait_for_reject_sfx"):
		await hole.call("wait_for_reject_sfx")

	get_tree().change_scene_to_file("res://Scenes/LactoseScreen.tscn")

func _on_progress_full() -> void:
	if ending:
		return
	ending = true

	get_tree().change_scene_to_file("res://Scenes/Level2WinScreen.tscn")

# -----------------------
# Helpers (safe items only)
# -----------------------

func _sum_safe_sizes(node: Node) -> float:
	var sum := 0.0

	if node.is_in_group("swalloable") and _is_safe(node):
		var r := _get_circle_radius_from_node(node)
		if r > 0.0:
			sum += r

	for child in node.get_children():
		sum += _sum_safe_sizes(child)

	return sum

func _is_safe(n: Node) -> bool:
	var milk_val: Variant = n.get("contains_milk") # null if missing
	var has_milk := (milk_val != null and bool(milk_val))
	return not has_milk

func _get_circle_radius_from_node(n: Node) -> float:
	if not (n is Node2D):
		return -1.0

	var n2d: Node2D = n as Node2D

	var cs: CollisionShape2D = n2d.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs == null or cs.shape == null:
		return -1.0

	if cs.shape is CircleShape2D:
		var base_r: float = (cs.shape as CircleShape2D).radius
		var s: float = max(n2d.global_scale.x, n2d.global_scale.y)
		return base_r * s

	return -1.0
