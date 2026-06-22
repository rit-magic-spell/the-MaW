extends Node3D

@export var target_node: Node3D



func _process(delta):
	position = Util.exp_decay(position, target_node.position, 15.0, delta)
	rotation = Util.exp_decay(rotation, target_node.rotation, 15.0, delta)
