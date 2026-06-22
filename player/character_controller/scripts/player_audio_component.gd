extends Node3D

class_name PlayerAudio

@export var Root: Player

@onready var footstep_jump: AudioStreamPlayer3D = $FootstepJump
@onready var footstep_one = $FootstepOne
@onready var footstep_two = $FootstepTwo

enum SOUND
{
	FOOTSTEP_GENERIC,
	FOOTSTEP_WOOD,
	FOOTSTEP_STONE,
	#...
	TAKE_DAMAGE,
	TAKE_DAMAGE_CRITICAL,
	HEAL,
	
	STOPWATCH_ACTIVATE
}

enum LOOP
{
	STOPWATCH_ACTIVE,
	HEARTBEAT,
}

@export_range(0.01, 10.0) var step_distance := 0.4

@export_range(0.01, 2.0) var footstep_pitch_min := 1.0
@export_range(0.01, 2.0) var footstep_pitch_max := 1.2

var accumulated_motion := Vector3.ZERO

func add_motion(motion_vector: Vector3):
	motion_vector.y = 0.0
	accumulated_motion += motion_vector
	var dist_travelled = accumulated_motion.length()
	if dist_travelled > step_distance:
		if Root.entity_body.is_on_floor():
			play_footstep()
		accumulated_motion = Vector3.ZERO
		
func play_footstep():
	var next_pitch = randf_range(footstep_pitch_min, footstep_pitch_max)
	var next_stream = footstep_one if randf() > 0.5 else footstep_two
	next_stream.pitch_scale = next_pitch
	next_stream.play()

func play_jump():
	var next_pitch = randf_range(footstep_pitch_min, footstep_pitch_max)
	footstep_jump.pitch_scale = next_pitch
	footstep_jump.play()


func play_landing():
	play_footstep()
