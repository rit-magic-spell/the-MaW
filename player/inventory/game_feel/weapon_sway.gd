extends Node3D
class_name PlayerWeaponSway

@export var Camera: PlayerCameraComponent

var Body: EntityBodyComponent
@export var sway_speed: float = 2.0

# Movement-based sway
@export var sway_amount: float = 0.05

# Bobbing (sinusoidal movement while walking)
@export var bob_amount: float = 0.025

# Recoil
@export var recoil_kick: float = 0.3
@export var recoil_recovery: float = 8.0
@export var max_recoil_angle: float = 75.0

var player_view: Node3D
var current_recoil_rot: float = 0.0
var current_recoil_pos: Vector3 = Vector3.ZERO
var time: float = 0.0
var body_was_on_floor := false

func _ready():
	Body = Camera.Body

func _process(delta: float):
	if not Body:
		return
	#print(position)
	time += delta
	
	var velocity = Body.velocity
	velocity.y = 0
	var move_intensity = clampf(velocity.length() / Body.Config.MAX_SPEED, 0.0, 1.0)
	# Calculate offsets...
	var final_offset = Vector3.ZERO
	if Body.is_on_floor() or body_was_on_floor:
		if move_intensity > 0.1:
			final_offset.x = sin(time * sway_speed) * move_intensity * sway_amount
			final_offset.y = sin(time * sway_speed * 2.0) * bob_amount * move_intensity
			
		else:
			time = Util.exp_decay(time, 0.0, 2.0, delta)
	elif not body_was_on_floor:
		var jump_max = sqrt(2 * Body.Config.GRAVITY * Body.Config.JUMP_HEIGHT)
		final_offset.y = -1 * clampf(Body.velocity.y, -jump_max, jump_max) * bob_amount
	# Add recoil
	final_offset += current_recoil_pos
	
	# Apply to THIS node (which is child of weapon/hand)
	position = final_offset
	rotation = Vector3(current_recoil_rot, 0.0, 0.0)
	
	body_was_on_floor = Body.is_on_floor()
	# Recoil recovery
	current_recoil_pos = Util.exp_decay(current_recoil_pos, Vector3.ZERO, 15, delta * recoil_recovery)
	current_recoil_rot = Util.exp_decay(current_recoil_rot, 0.0, 15, delta * recoil_recovery)

# Call this from your weapon when firing
func add_recoil(angle: float, kick: float):
	current_recoil_rot = deg_to_rad(angle)
	current_recoil_pos = Vector3(0.0, 0.0, kick)
	
