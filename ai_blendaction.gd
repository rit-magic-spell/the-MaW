@icon("res://npcs/node_icons/AIBlendActionIcon.svg")
extends Node
class_name AIBlendAction

var npc_owner: NPCBase
var ai_sequence: AISequence

var npc_state: NPCWorldState

## The fallback action used when no entry exists in [member sequence_action_table]
## for the NPC's previous sequence.
@export var default_action: AIAction

## Maps previous sequence names to the action that should play as an entry transition.
## [br][br]
## [b]Key:[/b] The name of the previously active sequence.[br]
## [b]Value:[/b] The [AIAction] to delegate to for that transition.[br][br]
## If the previous sequence name is not found, [member default_action] is used instead.
@export var sequence_action_table: Dictionary[String, AIAction] = {}

var internal_prev_sequence: String = ""

func setup_owner(npc: NPCBase, sequence: AISequence):
	npc_owner = npc
	npc_state = npc.world_state
	ai_sequence = sequence
	for action in sequence_action_table.values():
		action.setup_owner(npc, sequence)
	default_action.setup_owner(npc, sequence)


func start_action(npc: NPCBase):
	npc_owner = npc
	internal_prev_sequence = npc_owner.ai_sequencer.prev_sequence_name
	var selected_action = get_selected_action()
	
	if ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\tBlend Action [%s] selected action [%s], starting" % [name, selected_action.name])
	
	selected_action.start_action(npc)


func tick_physics(delta: float):
	get_selected_action().tick_physics(delta)

func tick_frame(delta: float):
	get_selected_action().tick_frame(delta)

func on_animation_complete(anim_name: String):
	get_selected_action().on_animation_complete(anim_name)

func get_next_sequence() -> String:
	return get_selected_action().get_next_sequence()

func interrupt_action():
	get_selected_action().interrupt_action()

func stop_action():
	get_selected_action().stop_action()

func get_selected_action():
	return sequence_action_table.get(internal_prev_sequence, default_action)

func _to_string():
	return name

func get_entity_state():
	var state_dict = {}
	state_dict["selected_action_state"] = get_selected_action().get_entity_state()
	state_dict["internal_prev_sequence"] = internal_prev_sequence
	return state_dict
	
func set_entity_state(state_dict):
	if not state_dict:
		return
	internal_prev_sequence = state_dict.get("internal_prev_sequence", "")
	var selected_action_state = state_dict.get("selected_action_state", {})
	get_selected_action().set_entity_state(selected_action_state)
