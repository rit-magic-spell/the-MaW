extends Node3D

class_name LogicNode

@export var id: String
@export var target: String
@export var opcode: Operation

enum Operation
{
	NONE, ## Stop the signal
	FORWARD, ## Ignore us, Just pass the signal forward with your own value
	SET, ## Set the target's value to whatever we have.
	ADD, ## 
	SUB,
	NEGATE,
	TOGGLE,
	# MULT,
	# DIV_I,
	# DIV_F,
	COMPARE_EQ,
	COMPARE_GT,
	COMPARE_LT,
	COMPARE_NE,
}

var value = null

@export var logic_manager: LogicManager

func get_uid():
	return Util.get_entity_id(self)

func get_value():
	return value
	
func set_value(any):
	value = any

func receive_handler(source):
	if source is not LogicNode:
		logic_manager.fire_target(get_uid(), self)
	else:
		receive(source)


func receive(source: LogicNode):
	match opcode:
		Operation.NONE:
			handle_none(source)
		Operation.SET:
			handle_set(source)
		Operation.ADD:
			handle_add(source)
		Operation.SUB:
			handle_add(source)
		Operation.NEGATE:
			handle_neg(source)
		Operation.TOGGLE:
			handle_toggle(source)
		Operation.COMPARE_EQ:
			handle_compare_eq(source)
		Operation.COMPARE_GT:
			handle_compare_gt(source)
		Operation.COMPARE_LT:
			handle_compare_lt(source)
		Operation.COMPARE_NE:
			handle_compare_ne(source)
		_:
			push_error("Unexpected opcode [" + str(opcode) + "] !")

func fire():
	logic_manager.fire_target(id, self)
	on_fire()

func on_fire():
	pass

func handle_none(_source):
	pass

func handle_forward(_source):
	fire()

func handle_set(source: LogicNode):
	value = source.get_value()
	
func handle_add(source: LogicNode):
	var src_val = source.get_value() 
	if _is_number(src_val):
		set_value(get_value() + src_val)

func handle_sub(source: LogicNode):
	var src_val = source.get_value() 
	if _is_number(src_val):
		set_value(get_value() - src_val)

func handle_neg(_source: LogicNode):
	if _is_number(get_value()):
		set_value(get_value() * -1)
		
func handle_toggle(_source: LogicNode):
	if _is_number(get_value()):
		if absi(get_value()) != 0:
			set_value(0)
		else:
			set_value(1)
			
	if get_value() is bool:
		set_value(not get_value())

func handle_compare_eq(source: LogicNode):
	var src_val = source.get_value()
	var cur_val = value
	var string_comp = cur_val is String and src_val is String and cur_val == src_val
	var number_comp = _comp_number_eq(cur_val, src_val)
	var bool_comp = cur_val is bool and src_val is bool and cur_val == src_val
	
	if string_comp or number_comp or bool_comp:
		fire()
		
func handle_compare_gt(source: LogicNode):
	var src_val = source.value
	var cur_val = value
	
	if _comp_number_gt(cur_val, src_val):
		fire()

func handle_compare_lt(source: LogicNode):
	var src_val = source.get_value()
	var cur_val = get_value()
	
	if _comp_number_lt(cur_val, src_val):
		fire()
		
func handle_compare_ne(source: LogicNode):
	var src_val = source.get_value()
	var cur_val = get_value()
	
	if src_val != cur_val:
		fire()

func _comp_number_eq(cur_val, src_val):
	if not (_is_number(cur_val) and _is_number(src_val)):
		return false
		
	var src_type = typeof(src_val)
	var cur_type = typeof(cur_val)
	
	if src_type == cur_type:
		if src_type == TYPE_FLOAT:
			return is_equal_approx(src_val, cur_val)
		return src_val == cur_val
	return floori(src_val) == floori(cur_val)
	
func _comp_number_gt(cur_val, src_val):
	if not (_is_number(cur_val) and _is_number(src_val)):
		return false
		
	return src_val > cur_val
	
func _comp_number_lt(cur_val, src_val):
	if not (_is_number(cur_val) and _is_number(src_val)):
		return false
		
	return src_val < cur_val
	
func _is_number(num):
	return num is int or num is float
	
func save_entity_state(game_state: GameState):
	var properties = Util.get_trimmed_property_list(self, ["logic_manager"])
	var state_dict = Util.serialize_to_dict(self, properties)
	game_state.submit_state(get_uid(), state_dict)
	
func load_entity_state(game_state: GameState):
	var state_dict = game_state.retrieve_state(get_uid())
	if not state_dict:
		push_warning("No state dict exists for [%s], using default" % get_uid())
		return
	
	Util.deserialize_from_dict(self, state_dict)
