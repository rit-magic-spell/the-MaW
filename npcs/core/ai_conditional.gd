
@tool
extends Resource

class_name AICondition

enum VARIABLES
{
	DISTANCE_TO_TARGET,
	DISTANCE_TO_HOME,
	ANGLE_TO_TARGET_DEG,
	CURRENT_HEALTH,
	
	## Time since the AI Sequence started, including loops.
	SEQUENCE_TIME,
	RANDOM_VALUE,
	
	JUST_TOOK_DAMAGE,
	IS_TARGET_VISIBLE,
	IS_TARGET_IN_FOV,
	IS_TARGET_REACHABLE,
	
	ALWAYS,
	
	## TODO: Move these around to make them fit in menus better
	IS_TARGET_VISIBILITY_REMEMBERED,
	IS_TARGET_PLAYER
}

enum COMPARISON_TYPE
{
	NUMBER,
	BOOL,
	CONSTANT
}

enum COMPARISONS_NUM
{
	LESS_THAN,
	GREATER_THAN,
	EQUAL,
	NOT
}

enum COMPARISONS_BOOL
{
	TRUE,
	FALSE
}

@export var check_variable: VARIABLES :
	set(value):
		check_variable = value
		notify_property_list_changed()

#region Numeric Comparison

@export var check_num_comparison: COMPARISONS_NUM
@export var check_value: float

const num_names = ["check_num_comparison", "check_value"]

#endregion

#region Boolean Comparison

@export var check_bool_comparison: COMPARISONS_BOOL

const bool_names = ["check_bool_comparison"]

#endregiona

## The sequence to navigate if the condition is true. [br][br]
## 
## NOTE: A special case occurs if multiple sequence names are 
## separated by a ';' character [br](Ex. "WalkForward; WalkBackward")[br][br]
## When this occurs, a RANDOM sequence will be picked from the list,
## with equal weight applied to all options.
@export var sequence_name: String

var last_comp_value = true
func evaluate(world_state: NPCWorldState, action_owner: AIAction) -> bool:
	if check_variable == VARIABLES.ALWAYS:
		return true
		

	var comp_value = get_comp_value(world_state, action_owner)
	last_comp_value = comp_value
	var result: bool = do_compare(comp_value)
	return result


var sequence_candidates = []
func get_next_sequence():
	if not sequence_candidates:
		sequence_candidates = []
		var candidates = sequence_name.split(";")
		for candidate in candidates:
			sequence_candidates.append(candidate.strip_edges())
	
	return sequence_candidates.pick_random()

func get_comp_value(world_state: NPCWorldState, action_owner: AIAction):
	var comp_value = 0.0
	match check_variable:
		VARIABLES.DISTANCE_TO_TARGET:
			comp_value = world_state.get_distance_to_target()
		VARIABLES.DISTANCE_TO_HOME:
			comp_value = world_state.get_distance_to_home()
		VARIABLES.ANGLE_TO_TARGET_DEG:
			comp_value = world_state.get_angle_to_target()
		VARIABLES.CURRENT_HEALTH:
			comp_value = world_state.npc_health.current_health
		VARIABLES.SEQUENCE_TIME:
			comp_value = action_owner.ai_sequence.get_sequence_time()
		VARIABLES.RANDOM_VALUE:
			comp_value = randf()
		VARIABLES.JUST_TOOK_DAMAGE:
			comp_value = world_state.just_took_damage()
		VARIABLES.IS_TARGET_VISIBLE:
			comp_value = world_state.is_target_visible()
		VARIABLES.IS_TARGET_VISIBILITY_REMEMBERED:
			comp_value = world_state.is_target_visibility_remembered()
		VARIABLES.IS_TARGET_IN_FOV:	
			comp_value = world_state.is_target_in_fov()
		VARIABLES.IS_TARGET_REACHABLE:
			comp_value = world_state.is_target_reachable()
		VARIABLES.IS_TARGET_PLAYER:
			comp_value = world_state.get_target() is EntityBodyComponent
	return comp_value

func do_compare(value) -> bool:
	var comp_type = _get_variable_comp_type()
	match comp_type:
		COMPARISON_TYPE.CONSTANT:
			return true
		COMPARISON_TYPE.BOOL:
			return comp_bool(value)
		COMPARISON_TYPE.NUMBER:
			return comp_number(value)
	
	return false

func comp_bool(value: bool) -> bool:
	match check_bool_comparison:
		COMPARISONS_BOOL.TRUE:
			return value == true
		COMPARISONS_BOOL.FALSE:
			return value == false
	push_error("Invalid bool comparison?")
	return false


func comp_number(value: float) -> bool:
	match check_num_comparison:
		COMPARISONS_NUM.LESS_THAN: 
			return value < check_value
		COMPARISONS_NUM.GREATER_THAN:
			return value > check_value
		COMPARISONS_NUM.EQUAL:
			return is_equal_approx(value, check_value)
		COMPARISONS_NUM.NOT:
			return not is_equal_approx(value, check_value)
	push_error("Invalid numeric comparison?")
	return false

func _validate_property(property: Dictionary):
	# Show/hide based on variable type
	var comp_type = _get_variable_comp_type()
	match comp_type:
		COMPARISON_TYPE.CONSTANT:
			if property.name in num_names or property.name in bool_names:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		COMPARISON_TYPE.BOOL:
			if property.name in num_names:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		COMPARISON_TYPE.NUMBER:
			if property.name in bool_names:
				property.usage = PROPERTY_USAGE_NO_EDITOR

func _get_variable_comp_type() -> COMPARISON_TYPE:
	var result = COMPARISON_TYPE.CONSTANT
	match check_variable:
		VARIABLES.DISTANCE_TO_TARGET, \
		VARIABLES.DISTANCE_TO_HOME, \
		VARIABLES.ANGLE_TO_TARGET_DEG, \
		VARIABLES.CURRENT_HEALTH, \
		VARIABLES.SEQUENCE_TIME, \
		VARIABLES.RANDOM_VALUE:
			result = COMPARISON_TYPE.NUMBER
		VARIABLES.IS_TARGET_VISIBLE, \
		VARIABLES.IS_TARGET_IN_FOV, \
		VARIABLES.IS_TARGET_REACHABLE,\
		VARIABLES.JUST_TOOK_DAMAGE,\
		VARIABLES.IS_TARGET_VISIBILITY_REMEMBERED,\
		VARIABLES.IS_TARGET_PLAYER:
			result = COMPARISON_TYPE.BOOL
	
	return result
	
func _to_string() -> String:
	
	var comp_type = _get_variable_comp_type()
	var out = ""
	if comp_type == COMPARISON_TYPE.NUMBER:
		var var_str = VARIABLES.keys()[check_variable]
		var comp_str = COMPARISONS_NUM.keys()[check_num_comparison]
		var comp_val = last_comp_value
		if comp_val is float:
			comp_val = snapped(comp_val, 0.01)
		out = "Is [%s (%s)] [%s] [%s]" % [var_str, comp_val, comp_str, str(check_value)]
	
	if comp_type == COMPARISON_TYPE.BOOL:
		var var_str = VARIABLES.keys()[check_variable]
		var comp_str = COMPARISONS_BOOL.keys()[check_bool_comparison]
		out = "Is [%s] [%s]" % [var_str, comp_str]
	
	if comp_type == COMPARISON_TYPE.CONSTANT:
		out = "ALWAYS"
	
	return out
	
	
