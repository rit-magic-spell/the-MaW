@tool
extends Node3D

@export var text: String = ""
@export var text_size: int = 24
@export var color: Color = Color.WHITE

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	var player: Player = GameManager.player
	
	var distance_to_ply = player.entity_body.global_position.distance_to(global_position)
	
	if distance_to_ply < 10.0:
		DebugDraw3D.draw_text(
			global_position, 
			text, 
			text_size, 
			color)


func _func_godot_apply_properties(entity_properties: Dictionary):
	text = entity_properties.get("text", "")
	text_size = entity_properties.get("text_size", 24)
	color = entity_properties.get("color", Color.WHITE)
