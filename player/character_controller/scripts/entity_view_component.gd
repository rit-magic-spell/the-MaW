@tool
class_name EntityViewComponent extends Node3D

@export var Config : EntityConfig
@export var Body : EntityBodyComponent
@export var Inventory: EntityInventoryComponent

@export_subgroup("Gimbal")
@export var yaw_node : Node3D ## Y-axis Camera Mount gimbal.
@export var pitch_node : Node3D ## X-axis Camera Mount gimbal.
@export var camera_target : Node3D ## Used for player view aesthetics such as view tilt and bobbing.

@export var smooth_steps := true

var stored_recoil = 0.0

var recoil_accumulator: Vector2 = Vector2.ZERO

func get_forward() -> Vector3:
	return -camera_target.global_basis.z

func get_right() -> Vector3:
	return camera_target.global_basis.x

func _process(delta: float) -> void:
	handle_recoil(delta)
		
	
	#if stored_recoil > 0.0:
		#pitch_node.rotation.x += stored_recoil * delta
		#pitch_node.rotation.x = clamp(pitch_node.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		#pitch_node.orthonormalize()
		#stored_recoil *= 0.85
		#if stored_recoil <= 0.25:
			#stored_recoil = 0.0

func _physics_process(delta) -> void:
	if not Body:
		return
	
	if Engine.is_editor_hint():
		return
	
	# Add some view bobbing to the Camera Mount
	camera_bob(delta)
	
	global_position = Body.view_target.global_position
	if smooth_steps:
		global_position += camera_offset
	
	camera_target.rotation.z = calc_roll(Config.ROLL_ANGLE, Config.ROLL_SPEED)*2
	
	camera_offset = Util.exp_decay(camera_offset, Vector3.ZERO, 10.0, delta)

var rolling_multiplier = 1.0
# Manipulates the Camera Mount gimbals.
func handle_camera_input(look_input: Vector2, delta: float) -> void:
	var multiplier: float = 1.0
	var weapon = Inventory.entity_loadout_component.get_current_weapon()
	
	if weapon != null:
		multiplier = weapon.get_current_restrictions().get("sensitivity_multiplier", 1.0)
	
	rolling_multiplier = Util.exp_decay(rolling_multiplier, multiplier, 50, delta)
	
	var real_look_input = look_input * rolling_multiplier
	
	yaw_node.rotate_object_local(Vector3.DOWN, real_look_input.x)
	yaw_node.orthonormalize()
	
	pitch_node.rotate_object_local(Vector3.LEFT, real_look_input.y)
	__clamp_camera()

func set_player_rotation(yaw: float, pitch: float):
	yaw_node.rotation.y = deg_to_rad(yaw) 
	pitch_node.rotation.x = deg_to_rad(pitch)
	__clamp_camera()
	
# Creates a sinusoidal Camera Mount bobbing motion whilst moving.
func camera_bob(delta) -> void:
	if not Body:
		return
	var bob : float
	var simvel : Vector3
	simvel = Body.velocity
	simvel.y = 0
	
	if Config.BOB_FREQUENCY == 0.0 or Config.BOB_FRACTION == 0:
		return
	
	if Body.is_on_floor():
		bob = lerp(0.0, sin(Time.get_ticks_msec() * Config.BOB_FREQUENCY) / Config.BOB_FRACTION, (simvel.length() / 2.0) / Config.FORWARD_SPEED)
	else:
		bob = 0.0
	camera_target.position.y = Util.exp_decay(camera_target.position.y, bob, 5.0, delta)

func add_recoil(vertical: float, horizontal: float):
	recoil_accumulator.y += vertical
	recoil_accumulator.x += horizontal * randf_range(-1.0, 1.0)

# Returns a value for how much the Camera Mount should tilt to the side.
func calc_roll(rollangle: float, rollspeed: float) -> float:
	
	if Config.ROLL_ANGLE == 0.0 or Config.ROLL_SPEED == 0:
		return 0
	
	var side = Body.velocity.dot(yaw_node.transform.basis.x)
	
	var roll_sign = 1.0 if side < 0.0 else -1.0
	
	side = absf(side)
	
	var value = rollangle
	
	if (side < rollspeed):
		side = side * value / rollspeed
	else:
		side = value
	
	return side * roll_sign

func handle_recoil(delta: float):
	if recoil_accumulator.length_squared() <= 0.0:
		return
	pitch_node.rotation.x += recoil_accumulator.y * delta
	yaw_node.rotation.y += recoil_accumulator.x * delta
	__clamp_camera()
	recoil_accumulator = Util.exp_decay(recoil_accumulator, Vector2.ZERO, 16, delta)
	if recoil_accumulator.length_squared() < 0.001:
		recoil_accumulator = Vector2.ZERO

var camera_offset: Vector3 = Vector3.ZERO
func offset_camera(new_offset: Vector3):
	camera_offset += new_offset

func __clamp_camera():
	pitch_node.rotation.x = clamp(pitch_node.rotation.x, deg_to_rad(-89), deg_to_rad(89))
	pitch_node.orthonormalize()
	
func get_entity_state():
	var state = {}
	var yaw = rad_to_deg(yaw_node.rotation.y)
	var pitch = rad_to_deg(pitch_node.rotation.x)
	state["rotation"] = Vector3(pitch, yaw, 0.0)
	return state
	
func set_entity_state(state_dict):
	var rot_raw = state_dict["rotation"]
	var yaw = rot_raw.y
	var pitch = rot_raw.x
	set_player_rotation(yaw, pitch)
