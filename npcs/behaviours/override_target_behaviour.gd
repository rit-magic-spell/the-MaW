
extends AIBehaviour

## Toggles "Visible" on a given node, based on settings.
class_name OverrideTargetBehaviour

enum CUSTOM_TARGET
{
	PLAYER, # then why would you use this lmao
	NEAREST_LIVING_NPC,
	NEAREST_DEAD_NPC,
	CUSTOM_NODE
}

@export var custom_target: CUSTOM_TARGET = CUSTOM_TARGET.PLAYER
@export var custom_target_node: NodePath


func _get_custom_target():
	match custom_target:
		CUSTOM_TARGET.PLAYER:
			return npc_owner.get_target()
		CUSTOM_TARGET.NEAREST_LIVING_NPC:
			return _get_nearest_npc()
		CUSTOM_TARGET.NEAREST_DEAD_NPC:
			return _get_nearest_npc(true)
		CUSTOM_TARGET.CUSTOM_NODE:
			return action_owner.get_node(custom_target_node)
	

func _get_nearest_npc(entity_is_dead = false):
	var radius = 25.0
	var pos = npc_owner.world_state.get_target().global_position
	var results: Array[TraceQuery.TraceHit] = TraceQuery.overlap_sphere(pos, radius, TraceMask.NPC)
	
	var score = func score_hit(hit: TraceQuery.TraceHit):
		var collider = hit.hit_collider
		var collider_is_invalid = (collider == npc_owner) or (collider is not NPCBase)
		if collider_is_invalid:
			return Util.BIG_NUMBER
		
		var npc : NPCBase = collider
		var npc_is_invalid = npc.entity_health.is_entity_dead() != entity_is_dead
		
		if npc_is_invalid:
			return Util.BIG_NUMBER
		
		var flattened_pos = pos 
		flattened_pos.y = hit.hit_pos.y
		return flattened_pos.distance_squared_to(hit.hit_pos) 
		
	var best_hit = Util.find_min_by_score(results, score)
	if not best_hit:
		return null
	
	var collider = best_hit.hit_collider
	if collider is not NPCBase:
		return null
	
	var npc: NPCBase = collider
	
	if npc.entity_health.is_entity_dead() != entity_is_dead:
		return null
	
	return best_hit.hit_collider

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Override Target behaviour!")
	
	npc_owner.set_target_override(_get_custom_target())
	
func tick_physics(_delta: float):
	pass

func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Override Target behaviour!")
	
	npc_owner.clear_target_override()
