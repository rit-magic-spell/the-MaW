extends Node

@onready var logic_node_map: Dictionary[String, LogicNode]
@onready var logic_group_map: Dictionary[String, Array] = {}
@onready var logic_target_map: Dictionary[String, String] = {}

@export var enable_debug := false

## Used for "staging" to swap between frames 
var setup_target_queue = []
## Contains tuples of (source, target)
var target_queue = []

func _physics_process(_delta: float) -> void:
	tick_targets()

func fire_target(target_name: String, caller: Node3D, signal_data: Dictionary = {}):
	## Adds a caller's target to the queue of things to be fired.
	if not get_tree().has_group(target_name):
		push_warning("No target [%s] exists! Ignoring." % target_name)
		return
	
	signal_data["caller"] = caller
	
	var targets = get_tree().get_nodes_in_group(target_name)
	var pairs = []
	for target in targets:
		var obj_dict = {
			0 : signal_data.duplicate_deep(),
			1: target
		}
		pairs.append(obj_dict)
	setup_target_queue.append_array(pairs)


func tick_targets():
	while not target_queue.is_empty():
		var object_pair = target_queue.pop_front()
		
		var signal_data = object_pair[0]
		var object = object_pair[1]
		if object.has_method("handle_signal"):
			object.handle_signal(signal_data)
			if enable_debug:
				DebugDraw3D.draw_arrow(signal_data["caller"].global_position, object.global_position, Color.GREEN, 0.0625, false, 1.5)
			
		else:
			push_error("Registered object [%s] does not have the handle_signal method!" % object.name)
		
	target_queue = setup_target_queue.duplicate()
	setup_target_queue.clear()
	
