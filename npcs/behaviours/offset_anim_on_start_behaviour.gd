
extends AIBehaviour

## Applies a random offset to a given behaviour the first time it's loaded. 
## Intended for use in idle sequences, to scatter monster behaviour
class_name OffsetAnimOnStartBehaviour

var first_time_setup = false

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up OffsetAnimOnStart behaviour!")
	
	
func tick_physics(_delta: float):
	pass

func tick_frame(_delta: float):
	if not first_time_setup:
		var animator = action_owner.npc_owner.animation_player
		var anim_length = animator.current_animation_length
		animator.advance(anim_length * randf())
		first_time_setup = true
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down OffsetAnimOnStart behaviour!")
