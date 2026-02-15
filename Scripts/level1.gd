extends Node2D

@onready var hole: Node = $Hole
@onready var hud: CanvasLayer = $UI_HUD
@onready var bgm: AudioStreamPlayer = $BGM

var total_size: float = 0.0
var eaten_size: float = 0.0

func _ready() -> void:
	bgm.volume_db = -15
	bgm.play()

	await get_tree().process_frame

	total_size = _sum_all_swallowable_radii(self)
	eaten_size = 0.0

	print("TOTAL SIZE:", total_size)

	hud.set_progress01(0.0)

	hole.swallowed.connect(_on_hole_swallowed)

	hud.time_up.connect(_on_time_up)

func _on_hole_swallowed(eaten_r: float) -> void:
	eaten_size += eaten_r

	var p := 0.0
	if total_size > 0.0:
		p = eaten_size / total_size

	hud.set_progress01(p)
	print("eaten_r=", eaten_r, " eaten_size=", eaten_size, " p=", p)

	if p >= 0.999:
		_on_progress_full()

func _on_time_up() -> void:
	if is_instance_valid(bgm):
		bgm.stop()

	get_tree().change_scene_to_file("res://Scenes/TimerLossScreen.tscn")

func _on_progress_full() -> void:
	if is_instance_valid(bgm):
		bgm.stop()

	get_tree().change_scene_to_file("res://Scenes/Level1WinScreen.tscn")


func _sum_all_swallowable_radii(node: Node) -> float:
	var sum := 0.0

	if node.is_in_group("swalloable"):
		var r := _get_circle_radius_from_node(node)
		if r > 0.0:
			sum += r

	for child in node.get_children():
		sum += _sum_all_swallowable_radii(child)

	return sum

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
