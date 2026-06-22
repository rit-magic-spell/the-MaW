@tool
extends Node3D

@export var target: String
@export var required_item := ""

func _func_godot_apply_properties(properties: Dictionary):
	target = properties.get("target", "")
	required_item = properties.get("required_item", "")
