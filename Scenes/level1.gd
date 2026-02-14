extends Node2D

@onready var hole: Node = $Hole
@onready var hud: CanvasLayer = $UI_HUD

var total := 0
var swallowed := 0

func _ready() -> void:
	# count how many swalloables exist at start
	total = get_tree().get_nodes_in_group("swalloable").size()

	# start at 0%
	hud.set_progress01(0.0)

	# connect hole -> progress
	hole.swallowed.connect(_on_hole_swallowed)

	# connect timer -> test
	hud.time_up.connect(_on_time_up)

func _on_hole_swallowed() -> void:
	swallowed += 1

	var p := 0.0
	if total > 0:
		p = float(swallowed) / float(total)

	hud.set_progress01(p)

	if swallowed >= total:
		_on_progress_full()


func _on_time_up() -> void:
	print("TIME UP")


func _on_progress_full() -> void:
	print("LEVEL COMPLETE")
