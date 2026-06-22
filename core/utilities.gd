extends Node

## Nodes

func get_child_nodes_of_type(base: Node, node_type: Variant) -> Array:
	var result: Array = []
	for child in base.get_children():
		if is_instance_of(child, node_type):
			result.append(child)
		result.append_array(get_child_nodes_of_type(child, node_type))
	return result

const BIG_NUMBER = 999999999999.0
func find_min_by_score(items: Array, score_func: Callable) -> Variant:
	if not items:
		return null
	
	var best_item = items[0]
	var best_score = score_func.call(best_item)
	
	for i in range(1, items.size()):
		var item = items[i]
		var score = score_func.call(item)
		if score < best_score:
			best_item = item
			best_score = score
	
	return best_item


func is_node_child_of(node: Node, potential_parent: Node) -> bool:
	var current = node
	while current:
		if current == potential_parent:
			return true
		current = current.get_parent()
	return false


func get_entity_id(entity: Node3D) -> String:
	var pos = entity.global_transform.origin.snapped(Vector3(0.1, 0.1, 0.1))
	var rot = entity.global_transform.basis.get_euler().snapped(Vector3(0.01, 0.01, 0.01))
	return "%s|%s|%s" % [entity.name, pos, rot]

func get_target_id_from_str(entity_name: String):
	return "ENTITY_" + entity_name

func get_target_id(entity: Node3D) -> String:
	if not entity.get_property_list().has("targetname"):
		push_error("Node [%s] does not have a targetname property!" % entity.name)
		return ""
	
	if not entity.targetname:
		push_error("Node [%s] has an empty target name!" % entity.name)
		return ""
	
	return get_target_id_from_str(entity.targetname)

func get_trimmed_property_list(obj: Object, filter: Array[String] = []):
	var result = []
	for prop in obj.get_property_list():
		if (prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE) and prop.name not in filter:
			result.append(prop.name)
	return result

func serialize_to_dict(obj: Object, saved_properties: Array = []):
	var properties = saved_properties.duplicate()
	
	if not saved_properties:
		properties = get_trimmed_property_list(obj)
	
	var result = {}
	for prop_name in properties:
		result[prop_name] = obj.get(prop_name)
	return result
	
func deserialize_from_dict(obj: Object, state_dict: Dictionary):
	for prop_name in state_dict:
		obj.set(prop_name, state_dict[prop_name])

## Math

## Get the angle to a target based off of a forward vector, in radians.
func get_signed_angle_from_forward(target_vector: Vector3, forward_vector: Vector3):
	var to_target = target_vector.normalized()
	var forward = forward_vector.normalized()
	var unsigned_angle = forward.normalized().angle_to(to_target)
	var cross = forward.cross(to_target)
	return unsigned_angle * sign(cross.y)

## Exponentially decay frame independently
## decayConstant is small for slow decay and large for fast decay.
## Recommended value range is from 1.0 to 25.0
func exp_decay(current: Variant, target: Variant, decayConstant: float, delta: float):
	var result = target + (current - target) * (exp(-decayConstant * delta))
	return result


func drop_to_ground(position: Vector3) -> Vector3:
	
	var hit_result = TraceQuery.raycast(position, Vector3.DOWN, TraceMask.WORLD)
	if hit_result.is_empty():
		return Vector3.ZERO
	
	return hit_result.hit_pos
