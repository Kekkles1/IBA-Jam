extends Control

@onready var bgm: AudioStreamPlayer = $BGM

func _ready() -> void:
	bgm.volume_db = -15
	bgm.play()
	
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/StartScreen.tscn")
