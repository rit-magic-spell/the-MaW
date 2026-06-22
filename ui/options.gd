extends Control

class_name PlayerOptionsComponent

@export var player: Player

@onready var sensitivity: SensitivityManager = $ColorRect/VBoxContainer/Control/Control

func _ready():
	call_deferred("setup_sensitivity")

func setup_sensitivity():
	sensitivity.setup(player)


func _on_continue_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var input = player.player_input
	input.HUD.visible = true
	input.Options.visible = false


func _on_quit_pressed() -> void:
	get_tree().quit()
