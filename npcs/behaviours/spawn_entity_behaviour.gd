extends AIBehaviour

class_name SpawnEntityBehaviour

enum SPAWN_LOCATION
{
	SELF,
	TARGET,
	LOCAL_POSITION,
	NPC_NEAREST_TARGET,
	NPC_NEAREST_SELF,
	DEAD_NPC_NEAREST_TARGET,
	DEAD_NPC_NEAREST_SELF
}


@export var entity_scene: PackedScene

@export var spawn_location: SPAWN_LOCATION = SPAWN_LOCATION.SELF

@export var optional_position: NodePath

var spawned_obj: DynamicEntity

var optional_spawn_node: Node3D

func _ready():
	if Engine.is_editor_hint():
		return
	call_deferred("_load_object_shaders")

func _load_object_shaders():
	var temp_obj = entity_scene.instantiate()
	temp_obj.call_deferred("queue_free")

func setup_behaviour():
	spawned_obj = entity_scene.instantiate()
	npc_owner.get_owner().add_child(spawned_obj)
	
	optional_spawn_node = action_owner.get_node(optional_position) if optional_position else null
	
	spawned_obj.global_position = get_spawn_position()
	spawned_obj.setup_entity(npc_owner, entity_scene)


func tick_frame(_delta: float):
	pass
	
func tick_physics(_delta: float):
	pass

func interrupt_behaviour():
	if not spawned_obj:
		return
	spawned_obj.interrupt_entity()

func teardown_behaviour():
	pass

func get_spawn_position() -> Vector3:
	var loc = Vector3.ZERO
	match spawn_location:
		SPAWN_LOCATION.SELF:
			loc = npc_owner.global_position
		SPAWN_LOCATION.TARGET:
			if not npc_owner.world_state.has_target():
				loc = npc_owner.global_position
				push_error("Tried to spawn an entity at a nonexistent target! Defaulting to local pos.")
			else:
				loc = Util.drop_to_ground(npc_owner.world_state.get_target().global_position)
		SPAWN_LOCATION.LOCAL_POSITION:
			if not optional_spawn_node: 
				push_error("Tried to use local position for spawn but no node existed!")
			else:
				loc = optional_spawn_node.global_position
		SPAWN_LOCATION.NPC_NEAREST_TARGET:
			loc = find_npc_near_player()
		SPAWN_LOCATION.NPC_NEAREST_SELF:
			loc = find_npc_near_self()
		SPAWN_LOCATION.DEAD_NPC_NEAREST_TARGET:
			loc = find_npc_near_player(true)
		SPAWN_LOCATION.DEAD_NPC_NEAREST_SELF:
			loc = find_npc_near_self(true)
	return loc
	

func find_npc_near_self(dead = false):
	return find_npc(npc_owner.global_position, dead)
	

func find_npc_near_player(dead = false):
	return find_npc(npc_owner.get_target().global_position, dead)
	
func find_npc(target_pos: Vector3, entity_is_dead = false):
	var radius = 25.0
	var pos = target_pos
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

	return Util.find_min_by_score(results, score)
