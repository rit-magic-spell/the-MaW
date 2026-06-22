class_name PlayerCameraComponent extends Node3D

@export_group("Components")
@export var Config : EntityConfig
@export var View : EntityViewComponent
@export var Body: EntityBodyComponent

@export var WeaponSway: PlayerWeaponSway
@export var animation_player: AnimationPlayer
@export_group("View Interpolation")
var target : Node3D ## The node this function mimics the transform of.
var t_prev : Transform3D
var t_curr : Transform3D
var update : bool = false

@export_group("Camera")
@export var camera_arm : SpringArm3D ## SpringArm3D that has it's rotation and extension distance set automatically.
@export var camera_anchor : Node3D ## Camera anchor node that is automatically rotated to compensate for the camera arm rotation.
@export var camera : Node3D ## Camera node that is automatically rotated to compensate for the camera anchor rotation.
@export var hand: Node3D ## Node used to spawn weapons and attach them to the player

@onready var night_light: OmniLight3D = $"Spring Arm/Camera Anchor/Camera/NightLight"


var base_nightlight_color: Color

func get_forward() -> Vector3:
	return -camera.global_basis.z

func _ready() -> void:
	set_as_top_level(true) # Detach from pawn node.
	# Initialize interpolation transforms.
	
	target = View.camera_target
	
	global_transform = target.global_transform
	t_prev = target.global_transform
	t_curr = target.global_transform
	base_nightlight_color = night_light.light_color

func _process(delta) -> void:
	
	interpolate(delta)
	# Modify camera nodes to conform with Player Config.
	# TODO: I have to make this not run every frame, but as far as I can tell, there is negligible impact on performance, so it stays.
	handle_camera_settings()
	night_light.light_color = Util.exp_decay(night_light.light_color, base_nightlight_color, 15.0, delta)

var prev_position = Vector3.ZERO
func _physics_process(delta) -> void:
	# Update the transforms.
	update_target()
	

func update_target() -> void:
	# Update interpolation transforms.
	t_prev = t_curr
	t_curr = target.global_transform

func get_hand_node() -> Node3D:
	return hand

func interpolate(delta) -> void:
	# Get the interpolation fraction.
	var f := Engine.get_physics_interpolation_fraction()
	
	# Interpolate camera.
	if should_interpolate():
		for i in range(3):
			global_transform.origin[i] = lerpf(t_prev.origin[i], t_curr.origin[i], f)
		global_rotation = target.global_rotation
	else:
		#global_position = Util.exp_decay(global_position, target.global_position, 0.1, delta)
		#global_rotation = Util.exp_decay(global_rotation, target.global_rotation, 0.1, delta)
		global_transform = target.global_transform
		pass



func handle_camera_settings() -> void:
	# Check if we are using third person.
	if (Config.THIRD_PERSON_CAMERA):
		# If so, rotate camera parts to "move" the camera.
		camera_arm.spring_length = Config.ARM_LENGTH
		camera_arm.rotation_degrees = Vector3(Config.ARM_OFFSET_DEGREES.x, Config.ARM_OFFSET_DEGREES.y, 0)
		camera_anchor.rotation_degrees.x = -Config.ARM_OFFSET_DEGREES.x
		camera.rotation_degrees.y = -Config.ARM_OFFSET_DEGREES.y
	else:
		# If not, reset.
		camera_arm.spring_length = 0
		camera_arm.rotation_degrees = Vector3.ZERO
		camera_anchor.rotation_degrees.x = 0
		camera.rotation_degrees.y = 0

func should_interpolate() -> bool:
	# See if the current rendering FPS is eligible for interpolation. 
	# (Eligible is above physics tick-rate or if the modulus of the tick-rate and rendering FPS is not 0)
	return Engine.get_frames_per_second() > Engine.physics_ticks_per_second || (Engine.physics_ticks_per_second % roundi(Engine.get_frames_per_second())) != 0

func add_weapon_recoil(angle, kick):
	WeaponSway.add_recoil(angle, kick)

func play_equip_animation(duration: float):
	var clip: Animation = animation_player.get_animation("equip")
	var clip_time = clip.length
	var modifier = clip_time / duration
	animation_player.seek(0.0, true, true)
	animation_player.play("equip", -1)
	animation_player.speed_scale = modifier
	
func play_dequip_animation(duration: float):
	var clip: Animation = animation_player.get_animation("equip")
	var clip_time = clip.length
	var modifier = clip_time / duration
	animation_player.seek(clip_time, true, true)
	animation_player.play_backwards("equip", -1)
	animation_player.speed_scale = modifier
