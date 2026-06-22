@icon("res://npcs/node_icons/AIActionIcon.svg")

extends Node

class_name AIAction

var npc_owner: NPCBase
var ai_sequence: AISequence

var npc_state: NPCWorldState

@export_range(0.0, 50.0) var speed_multiplier = 1.0

@export var animation: String
@export var conditions: Array[AICondition]
@export var behaviours: Array[AIBehaviour]

var duplicated_behaviours: Array[AIBehaviour]

func setup_owner(npc: NPCBase, sequence: AISequence):
	npc_owner = npc
	npc_state = npc.world_state
	ai_sequence = sequence
	var duplicate_mode = Resource.DeepDuplicateMode.DEEP_DUPLICATE_INTERNAL
	duplicated_behaviours = behaviours.duplicate_deep(duplicate_mode)
	validate_animation()

func validate_animation():
	var animator = npc_owner.animation_player
	if not animator.has_animation(animation):
		var error_str = "[%s] Tried to load invalid animation [%s]" % \
		[name, animation]
		push_error(error_str)

func start_action(npc: NPCBase):
	npc_owner = npc
	var animator = npc_owner.animation_player
	animator.play(animation, 0.0)
	animator.pause()
	if not animator.animation_finished.is_connected(on_animation_complete):
		npc_owner.animation_player.animation_finished.connect(on_animation_complete)
		
	if ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\tAction [%s] with animation [%s] starting" % [name, animation])
		
	for behaviour in duplicated_behaviours:
		if not behaviour:
			push_error("Null behaviour in action [%s]!" % [name])
		else:
			behaviour.start_behaviour(self, npc_owner)
	


func tick_physics(delta: float):
	for behaviour in duplicated_behaviours:
		if not behaviour:
			push_error("Null behaviour in action [%s]!" % [name])
		else:
			behaviour.tick_physics(delta)

func tick_frame(delta: float):
	for behaviour in duplicated_behaviours:
		if not behaviour:
			push_error("Null behaviour in action [%s]!" % [name])
		else:
			behaviour.tick_frame(delta)
	var true_delta = delta * speed_multiplier
	var animator = npc_owner.animation_player
	animator.advance(true_delta)

func on_animation_complete(anim_name: String):
	if anim_name != animation:
		push_error("Action with animation [%s] receiving on_complete signal for [%s]!" % \
		[animation, anim_name])
	ai_sequence.notify_action_complete()

func get_next_sequence() -> String:
	for condition in conditions:
		var result = condition.evaluate(npc_state, self)
		var debug_str = "\t\t\t" + str(condition) + " -> " + str(result)
		if ai_sequence.ai_sequencer.debug_sequencer:
			print(debug_str)
		if result:
			return condition.get_next_sequence()
	return ""

func interrupt_action():
	if ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\tAction [%s] with animation [%s] interrupting" % [name, animation])
	
	for behaviour in duplicated_behaviours:
		if behaviour:
			behaviour.interrupt_behaviour()
			behaviour.teardown_behaviour()
		else:
			push_error("Null behaviour in action [%s]!" % [name])
			
	if npc_owner.animation_player.animation_finished.is_connected(on_animation_complete):
		npc_owner.animation_player.animation_finished.disconnect(on_animation_complete)

func stop_action():
	if ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\tAction [%s] with animation [%s] stopping" % [name, animation])
		
	for behaviour in duplicated_behaviours:
		if behaviour:
			behaviour.teardown_behaviour()
		else:
			push_error("Null behaviour in action [%s]!" % [name])

		
	if npc_owner.animation_player.animation_finished.is_connected(on_animation_complete):
		npc_owner.animation_player.animation_finished.disconnect(on_animation_complete)

func _to_string():
	return name

func get_entity_state():
	var state_dict = {}
	state_dict["animation_pos"] = npc_owner.animation_player.current_animation_position
	return state_dict
	
func set_entity_state(state_dict):
	if not state_dict:
		return
	var animation_pos = state_dict["animation_pos"]
	npc_owner.animation_player.play(animation, -1)
	npc_owner.animation_player.seek(animation_pos)
