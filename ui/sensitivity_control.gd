extends Control

class_name SensitivityManager

@onready var sensitivity_slider: HSlider = $SensitivitySlider
@onready var rich_text_label: RichTextLabel = $RichTextLabel

var ply: Player
var base_sensitivity: float

func _ready():
	
	pass

func _process(_delta: float) -> void:
	if not ply or not ply.entity_body:
		return
	var config = ply.entity_body.Config
	rich_text_label.text = str(snapped(sensitivity_slider.value, 0.01))


func setup(player: Player):
	ply = player
	base_sensitivity = ply.entity_body.Config.MOUSE_SENSITIVITY
	sensitivity_slider.value = 1.0

func _on_sensitivity_slider_value_changed(value: float) -> void:
	if not ply:
		push_error("Tried to change sensitivity before player was assigned!")
		return
	var config = ply.entity_body.Config
	config.MOUSE_SENSITIVITY = base_sensitivity * value
