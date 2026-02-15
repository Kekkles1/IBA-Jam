extends Node2D

@onready var hole: Node = $Hole   # (this must be Hole_Level3 instance)
@onready var hud: CanvasLayer = $UI_HUD

var total_safe_size: float = 0.0
var eaten_safe_size: float = 0.0

# 0: savory, 1: savory, 2: sweet
var pattern_step: int = 0

func _ready() -> void:
	await get_tree().process_frame

	total_safe_size = _sum_safe_sizes(self)
	eaten_safe_size = 0.0
	pattern_step = 0

	hud.set_progress01(0.0)

	# hole emits swallowed(eaten_r, body)
	hole.swallowed.connect(_on_hole_swallowed)
	hud.time_up.connect(_on_time_up)

func try_accept_swallow(body: Node2D) -> bool:
	# only here in Level3; Hole_Level3 calls this BEFORE swallowing

	# milk items are not part of the objective
	if _has_milk(body):
		return false

	var savory_val: Variant = body.get("is_savory")
	var is_savory: bool = (savory_val != null and bool(savory_val))

	var ok: bool = false
	match pattern_step:
		0, 1:
			ok = is_savory
		2:
			ok = not is_savory

	if not ok:
		return false

	# accept + advance pattern
	pattern_step += 1
	if pattern_step > 2:
		pattern_step = 0

	return true

func _on_hole_swallowed(eaten_r: float, body: Node2D) -> void:
	# If we got here, it was accepted + swallowed already.
	# Update progress by size.
	eaten_safe_size += eaten_r

	var p := 0.0
	if total_safe_size > 0.0:
		p = eaten_safe_size / total_safe_size

	hud.set_progress01(p)

	if p >= 1.0:
		_on_progress_full()

func _on_time_up() -> void:
	print("TIME UP")

func _on_progress_full() -> void:
	print("LEVEL COMPLETE")

# ---------------- helpers ----------------

func _sum_safe_sizes(node: Node) -> float:
	var sum := 0.0

	if node.is_in_group("swalloable") and not _has_milk(node):
		var r := _get_circle_radius_from_node(node)
		if r > 0.0:
			sum += r

	for child in node.get_children():
		sum += _sum_safe_sizes(child)

	return sum

func _has_milk(n: Node) -> bool:
	var milk_val: Variant = n.get("contains_milk")
	return (milk_val != null and bool(milk_val))

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
