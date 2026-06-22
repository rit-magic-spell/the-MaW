
extends AIBehaviour

class_name OrientationBehaviour

enum OrientationMode {
	FACE_TARGET,           # Face player/enemy
	FACE_MOVEMENT_DIR,     # Face where moving
	MAINTAIN_CURRENT       # Don't change orientation
}

@export var orientation_mode: OrientationMode = OrientationMode.FACE_TARGET

@export var rate: float = 360.0

var rad_rate: float = 0.0

var hit_bodies = []

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Face Target behaviour!")
	rad_rate = deg_to_rad(rate)

const magic_cutoff_angle = 0.5
func tick_physics(delta: float):
	var angle_delta = __get_angle_delta(delta)
	var rot_rate = rad_rate * sign(angle_delta)
	var angle_slowdown_threshold = deg_to_rad(60)
	if abs(angle_delta) < angle_slowdown_threshold:
		var angle_slowdown = clampf(inverse_lerp(angle_slowdown_threshold, 0.0, abs(angle_delta)), 0.0, 1.0)
		rot_rate = lerp(rad_rate, 0.0, angle_slowdown) * sign(angle_delta)
	
	npc_owner.rotate(Vector3.UP, rot_rate * delta)

func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Face Target behaviour!")

func __get_angle_delta(delta) -> float:
	match orientation_mode:
		OrientationMode.FACE_TARGET:
			return npc_owner.world_state.get_angle_to_target()
		OrientationMode.FACE_MOVEMENT_DIR:
			return Util.get_signed_angle_from_forward(npc_owner.velocity, npc_owner.get_forward())
	return 0.0
		
	
