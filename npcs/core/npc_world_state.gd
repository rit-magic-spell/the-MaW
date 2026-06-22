extends Resource

class_name NPCWorldState

const REMEMBER_TIME = 10.0
const PATHING_FAILED_TIME = 1.0

var target: Node3D 

#region Visibility
## The angle you're facing _away_ from the target by.
## Positive is rotate RIGHT to face target.
## Negative is rotate LEFT to face target.
var angle_to_target: float = 180.0

var target_in_fov: bool = false

var target_visible: bool = false
var target_visible_remember_timer: float = 0.0

var was_target_visible: bool

#endregion

#region Pathfinding

var vector_to_target: Vector3 = Vector3.ZERO

var distance_to_target: float = 0.0

var distance_to_target_no_height: float = 0.0

var vector_to_home: Vector3 = Vector3.ZERO

var distance_to_home: float = 0.0

var no_path_timer: float = 0.0

#endregion

#region State

var health_decreased: bool
var prev_health: float = 0.0
var current_health: float = 0.0

#endregion

func has_target():
	return target != null

func is_target_visible():
	return has_target() and target_visible

func is_target_visibility_remembered():
	return has_target() and target_visible_remember_timer > 0.0

func is_target_just_visible():
	return has_target() and target_visible and not was_target_visible
	
func is_target_just_lost():
	return has_target() and not target_visible and was_target_visible

func is_target_in_fov():
	return has_target() and target_in_fov
	
func is_target_reachable():
	return has_target() and  no_path_timer < PATHING_FAILED_TIME

func just_took_damage():
	return health_decreased

func get_vector_to_target() -> Vector3:
	return vector_to_target

func get_target() -> Node3D:
	return target

func get_distance_to_target() -> float:
	return distance_to_target
	
func get_distance_to_target_no_height() -> float:
	return distance_to_target_no_height

func get_distance_to_home() -> float:
	return distance_to_home

## Get angle to target, in radians
func get_angle_to_target() -> float:
	return angle_to_target
	
func sample_world(npc: NPCBase, sample_pos: Vector3, target_node: Node3D, delta: float):
	_update_pathing(npc, sample_pos, target_node, delta)
	_update_visibility(npc, delta)
	_update_state(npc)

func clear_world():
	target_visible = false
	target_visible_remember_timer = -1.0
	was_target_visible = false
	target_in_fov = false
	

func _update_pathing(npc: NPCBase, sample_pos: Vector3, target_node: Node3D, delta: float):
	target = target_node
	if not target:
		return
	
	var target_pos = target.global_position
	vector_to_target = target_pos - sample_pos
	distance_to_target = vector_to_target.length()
	distance_to_target_no_height = vector_to_target.slide(Vector3.UP).length()
	
	vector_to_home = npc.npc_data.home_position - sample_pos
	distance_to_home = vector_to_home.length()
	
	npc.nav_agent.target_position = target_pos
	if npc.nav_agent.is_target_reachable():
		no_path_timer = 0.0
	else:
		no_path_timer += delta

func _update_visibility(npc: NPCBase, delta: float):
	was_target_visible = target_visible
	target_visible = _check_visiblity(npc)
	
	## A bit of a hack for now, intentional but it should be.. neater?
	if target_visible or npc.npc_data.status_target_always_visible:
		target_visible_remember_timer = REMEMBER_TIME
	else:
		target_visible_remember_timer -= delta
	
	angle_to_target = _get_angle_to_target(npc)
	target_in_fov = abs(angle_to_target) < deg_to_rad(npc.npc_data.field_of_view)

func _update_state(npc: NPCBase):
	prev_health = current_health
	current_health = npc.entity_health.current_health
	health_decreased = current_health < prev_health

func _check_visiblity(npc: NPCBase) -> bool:
	if distance_to_target <= 1.0:
		return true
	
	var target_dir = vector_to_target.slide(Vector3.UP).normalized()
	
	var npc_forward = npc.get_forward()
	var angle_from_forward = target_dir.angle_to(npc_forward)
	
	if angle_from_forward > deg_to_rad(npc.npc_data.field_of_view):
		return false
	
	# If this hits something and it's not the player, we can't see them.
	# Allows for corner peaking but it's quick to check.
	
	var trace = TraceQuery.linecast(
		npc.get_eye_position(), 
		target.global_position, 
		TraceMask.SOLID_FOR_NPC
	)
	
	if trace.is_empty():
		return true
	
	return false

func _get_angle_to_target(npc: NPCBase):
	return Util.get_signed_angle_from_forward(vector_to_target, npc.get_forward())

func get_entity_state():
	var saved_values = Util.get_trimmed_property_list(self, ["target"])
	return Util.serialize_to_dict(self, saved_values)
	
func set_entity_state(state_dict):
	if not state_dict:
		return
	Util.deserialize_from_dict(self, state_dict)
