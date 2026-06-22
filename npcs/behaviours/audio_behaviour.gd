
extends AIBehaviour

## Applies a random offset to a given behaviour the first time it's loaded. 
## Intended for use in idle sequences, to scatter monster behaviour
class_name AudioBehaviour

@export var audio_stream_player_path: NodePath

@export var stop_on_exit := false
@export var stop_on_interrupt := false

@export var pitch_shift = 0.05

var first_time_setup = false
var old_pitch := 1.0
func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Audio behaviour!")
	
	
	var audio = action_owner.get_node(audio_stream_player_path)
	var stream_player: AudioStreamPlayer3D = audio
	
	var sequence = action_owner.ai_sequence
	if stop_on_interrupt and not sequence.sequence_interrupted.is_connected(stream_player.stop):
		sequence.sequence_interrupted.connect(stream_player.stop)
		
	old_pitch = stream_player.pitch_scale
	stream_player.pitch_scale += randf_range(-pitch_shift, pitch_shift)
	stream_player.play()
	
	
func tick_physics(_delta: float):
	pass

func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Audio behaviour!")
	var audio = action_owner.get_node(audio_stream_player_path)
	if stop_on_exit:
		var stream_player: AudioStreamPlayer3D = audio
		stream_player.stop()
	audio.pitch_scale = old_pitch
