
extends AIBehaviour

## Toggles "Visible" on a given node, based on settings.
class_name VisibleBehaviour

@export var node_path: NodePath


## When you enter this state, what do you want the visibility set to?
@export var set_visibility_to := true

## When you exit this state, go to whatever value you had previously.
@export var reset_on_exit := true


var first_time_setup = false
var prev_visible := true


func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Visible behaviour!")
	
	var node: Node = action_owner.get_node(node_path)
	if node is Node3D:
		prev_visible = node.visible
		node.visible = set_visibility_to
	
	
	
func tick_physics(_delta: float):
	pass

func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Visible behaviour!")
	
	var node: Node = action_owner.get_node(node_path)
	if node is Node3D and reset_on_exit:
		node.visible = prev_visible
