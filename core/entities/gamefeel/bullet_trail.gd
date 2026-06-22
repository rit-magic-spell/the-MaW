extends Node3D

const NEAR_SPEED = 50.0 # m/s
const FAR_SPEED = 200.0 

var live_time = 0.0
var move_dir = Vector3.ZERO
var wake_time = 0.0

func _process(delta):
	if live_time <= 0.0:
		visible = false
		return
	
	visible = wake_time <= 0.0
	global_position += move_dir * real_speed * delta
	live_time -= delta
	wake_time -= delta

var real_speed: float
func setup(start_pos, forward, distance_to_end):
	if distance_to_end < 1.5:
		return
	
	var distance_lerp = clamp(inverse_lerp(5.0, 15.0, distance_to_end), 0.0, 1.0)
	real_speed = lerp(NEAR_SPEED, FAR_SPEED, distance_lerp)
	live_time = distance_to_end / real_speed
	wake_time = 0.01
	global_position = start_pos
	look_at(start_pos + forward)
	move_dir = forward

func is_active():
	return live_time > 0.0
