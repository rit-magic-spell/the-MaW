
extends AIBehaviour

## Changes collision on a given collider
class_name ChangeCollisionBehaviour

@export var collider_path: NodePath
@export_flags("World", "Player", "NPC", "Hitbox", "Trigger") var new_collision_layer: int = 0
@export_flags("World", "Player", "NPC", "Hitbox", "Trigger") var new_collision_mask: int = 0
@export var keep_changed_collision = false

var collision_mask 

var old_layer: int
var old_mask: int

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up ChangeCollisionBehaviour behaviour!")
	var collider = action_owner.get_node(collider_path) as CollisionObject3D
	if not collider:
		push_error("No collider for setup on Change Collision Behaviour on action [%s]" % action_owner.name)
		return
	old_layer = collider.collision_layer
	old_mask = collider.collision_mask
	collider.collision_layer = new_collision_layer
	collider.collision_mask = new_collision_mask
	
func tick_physics(_delta: float):
	pass

func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down ChangeCollisionBehaviour behaviour!")
	var collider = action_owner.get_node(collider_path) as CollisionObject3D
	if not collider:
		push_error("No collider for teardown on Change Collision Behaviour on action [%s]" % action_owner.name)
		return
	
	if not keep_changed_collision:
		collider.collision_layer = old_layer
		collider.collision_mask = old_mask
	
