
extends AIBehaviour

class_name MovementBehaviour

@export var movement_type: MOVEMENT_TYPE
## The percentage of the maximum speed you should move the entity at.
## [br]
## Example: 0.1 means move at 10% of the maximum speed of the NPC
@export_range(0.0, 1.0) var movement_percent = 1.0

@export var stop_near_player := false

@export var offset: Vector3


enum MOVEMENT_TYPE
{
	NAV_TO_TARGET,
	RELATIVE_TO_NPC,
	RELATIVE_TO_PLAYER,
	NAV_TO_HOME
}

var hit_bodies = []

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Movement behaviour!")

var prev_position := Vector3.ZERO 

func tick_physics(_delta: float):
	var next_velocity = Vector3.ZERO
	match movement_type:
		MOVEMENT_TYPE.NAV_TO_TARGET:
			next_velocity = _process_nav_to_target()
		MOVEMENT_TYPE.RELATIVE_TO_NPC:
			next_velocity = _process_relative_to_npc()
		MOVEMENT_TYPE.NAV_TO_HOME:
			next_velocity = _process_nav_to_home()
	

	next_velocity *= movement_percent

	if npc_owner.world_state.get_distance_to_target() < 1.2 and stop_near_player:
		return
		
	if npc_owner.npc_data.is_against_wall:
		next_velocity += Vector3.UP

	npc_owner.submit_velocity(next_velocity)

	
func tick_frame(_delta: float):
	pass
	
func _process_nav_to_target() -> Vector3:
	var target = npc_owner.get_target()
	var next_velocity_dir = npc_owner.get_next_vector_to_target(target.global_position + offset)
	return next_velocity_dir * npc_owner.npc_data.max_speed

func _process_nav_to_home() -> Vector3:
	var home = npc_owner.npc_data.home_position
	var next_velocity_dir = npc_owner.get_next_vector_to_target(home + offset)
	return next_velocity_dir * npc_owner.npc_data.max_speed

func _process_relative_to_npc() -> Vector3:
	return (npc_owner.transform.basis * offset) * npc_owner.npc_data.max_speed
	
	
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Movement behaviour!")
