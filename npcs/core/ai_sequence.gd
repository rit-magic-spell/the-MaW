@icon("res://npcs/node_icons/AISequenceIcon.svg")


extends Node

## Responsible for managing actions, starting and stopping them as they complete.
class_name AISequence

enum INTERRUPT_OVERRIDE_TYPE
{
	ALLOW_LIST,
	DENY_LIST
}

# Sequences are responsible for storing actions in a given order.
## Custom interrupts are for the specaial cases where you DO want to handle
## a traditionally non-handled interrupt. Think having the enemy react to seeing
## the player while on patrol
@export var custom_interrupts: Dictionary[AISequencer.INTERRUPT, String]


@export var interrupt_filter_mode: INTERRUPT_OVERRIDE_TYPE = INTERRUPT_OVERRIDE_TYPE.DENY_LIST
## Ignored interrupts are a checked list of interrupts that are NOT 
## handled by the sequence. For example, you can't flinch out of a death
## animation
@export var interrupt_filter: Array[AISequencer.INTERRUPT]

signal sequence_interrupted

var actions: Array = []
var current_action_idx = 0

var npc_owner: NPCBase
var ai_sequencer: AISequencer


## Time since the sequence first started playing.
## Includes loops
var sequence_time: float = 0.0

func _ready():
	_update_actions()
	
func setup_owner(npc: NPCBase, sequencer: AISequencer):
	npc_owner = npc
	ai_sequencer = sequencer
	for action in actions:
		action.setup_owner(npc, self)

func get_current_action():
	if current_action_idx >= len(actions):
		push_warning("\tCurrent Action Idx [%s] was too large for sequence [%s]! Assuming loading error.")
		current_action_idx %= len(actions)
	
	return actions[current_action_idx]


func start_sequence(npc: NPCBase):
	current_action_idx = 0
	sequence_time = 0.0
	npc_owner = npc
	var current_action = actions[current_action_idx]
	if current_action is AIAction or current_action is AIBlendAction:
		# This is for type checking.
		if ai_sequencer.debug_sequencer:
			print("\tSequence [%s] is starting" % [name])
		current_action.start_action(npc_owner)
	else:
		push_error("Action in actions list isn't action!?!?")

func restart_sequence(npc: NPCBase):
	current_action_idx = 0
	npc_owner = npc
	var current_action = actions[current_action_idx]
	if current_action is AIAction or current_action is AIBlendAction:
		# This is for type checking.
		if ai_sequencer.debug_sequencer:
			print("\tSequence [%s] is restarting" % [name])
		current_action.start_action(npc_owner)
	else:
		push_error("Action in actions list isn't action!?!?")

func tick_physics(delta: float):
	sequence_time += delta
	get_current_action().tick_physics(delta)

func tick_frame(delta: float):
	get_current_action().tick_frame(delta)

func interrupt_sequence():
	if ai_sequencer.debug_sequencer:
		print("\tInterrupting sequence [%s]" % [name])
	
	get_current_action().interrupt_action()
	sequence_interrupted.emit()

func end_sequence():
	if ai_sequencer.debug_sequencer:
		print("\tEnding sequence [%s]" % [name])
	get_current_action().stop_action()

func notify_action_complete():
	var next_sequence = get_current_action().get_next_sequence()
	if next_sequence:
		ai_sequencer.set_sequence(next_sequence)
	else:
		start_next_action()

func start_next_action():
	var next_idx = current_action_idx + 1
	if next_idx >= len(actions):
		if ai_sequencer.debug_sequencer:
			print("\tSequence [%s] complete, notifying sequencer." % [name])
		ai_sequencer.notify_sequence_reached_end()
		return
	set_next_action(next_idx)


func set_next_action(action_idx: int):
	var prev_action = get_current_action()
	if prev_action:
		prev_action.stop_action()
	current_action_idx = action_idx
	if ai_sequencer.debug_sequencer:
		print("\tSetting next action to [%s]" % current_action_idx)
	get_current_action().start_action(npc_owner)

func should_interrupt(interrupt: AISequencer.INTERRUPT):
	if interrupt in custom_interrupts:
		return true
	if interrupt_filter_mode == INTERRUPT_OVERRIDE_TYPE.ALLOW_LIST:
		if interrupt in interrupt_filter:
			return true
	elif interrupt_filter_mode == INTERRUPT_OVERRIDE_TYPE.DENY_LIST:
		if interrupt not in interrupt_filter:
			return true
	return false

## Returns the name of the next sequence to set, OR "" if no sequence is available.
func get_custom_interrupt_sequence(interrupt: AISequencer.INTERRUPT) -> String:
	if interrupt not in custom_interrupts:
		return ""
	return custom_interrupts[interrupt]

func get_sequence_time():
	return sequence_time

## On ready, each sequence builds an internal mapping of all actions.
## Of note, actions CAN BE in sub-nodes for easy grouping!
## As long as all actions are in order, everything will work 100% fine.
func _update_actions():
	var blend_actions = Util.get_child_nodes_of_type(self, AIBlendAction)
	actions.append_array(blend_actions)
	actions.append_array(Util.get_child_nodes_of_type(self, AIAction))
	
	# Blend Actions are a special case, they can have actions they reference that shouldn't
	# be picked up by the generous glob we do here. If you pick one up and a blend action we're
	# using for, you know, blending, skip it.
	for blend_action: AIBlendAction in blend_actions:
		for action in blend_action.sequence_action_table.values():
			actions.erase(action)
		actions.erase(blend_action.default_action)


const SAVED_PROPERTIES = [
	"current_action_idx"
]

func _to_string():
	return name

func get_entity_state():
	var state_dict = {}
	state_dict["current_action_idx"] = current_action_idx
	state_dict["current_action_state"] = get_current_action().get_entity_state()
	return state_dict
	
func set_entity_state(state_dict):
	if not state_dict:
		return
	var new_idx = state_dict["current_action_idx"]
	set_next_action(new_idx)
	get_current_action().set_entity_state(state_dict["current_action_state"])
	
