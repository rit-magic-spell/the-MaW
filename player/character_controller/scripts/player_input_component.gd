class_name PlayerInputComponent extends Node

@export_group("Components")
@export var Config : EntityConfig
@export var Body : EntityBodyComponent
@export var Inventory: EntityInventoryComponent
@export var Move : EntityMotionComponent
@export var View : EntityViewComponent
@export var HUD: Control
@export var Options: PlayerOptionsComponent

@export_group("Config")

@export var controller_look_curve: Curve

@export_group("Info")

@export var is_using_mouse := true

@onready var jump_cooldown_timer: Timer = $JumpCooldownTimer
@onready var bunnyhop_timer: Timer = $BunnyhopTimer
@onready var evade_timer: Timer = $EvadeTimer
@onready var coyote_timer: Timer = $CoyoteTimer

const JOYSTICK_DEADZONE = 0.1

# Inputs
var movement_input : Vector3
var mouse_input : Vector2
var joystick_look_input: Vector2
var move_dir : Vector3
var jump_on : bool
var duck_on : bool
var evade_input: bool

var attack_input : bool
var alt_attack_input : bool
var reload_input : bool

@onready var autohop_time: float = bunnyhop_timer.wait_time

# Jump Queueing
@export var has_midair_queued = false
@export var has_jumped = false

# evade/Dashing
@export var can_evade = false
@export var evade_accel_multiplier = 1.0


var scroll_hack_enabled = false
var body_floor_snap = 0.0
func _ready() -> void:
	Input.set_use_accumulated_input(false) # Disable accumulated input for precise inputs.
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Capture the mouse.
	body_floor_snap = Body.floor_snap_length

func _input(event) -> void:
	
	#---------------------
	# Replace with your own implementation of MOUSE_MODE switching!!
	#---------------------
	
	
	if event is InputEventKey or event is InputEventJoypadButton:
		if event.is_action_pressed("ui_cancel"):
			if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			HUD.visible = not HUD.visible
			Options.visible =  not HUD.visible
		return
	
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			# Grab the event data and process it.
			gather_mouse_input(event) 
			is_using_mouse = true
			
		if event is InputEventJoypadMotion:
			gather_joystick_look_input(event)
			is_using_mouse = false

func _process(_delta) -> void:
	# Reset mouse input to avoid drift.
	mouse_input = Vector2.ZERO
	
	if joystick_look_input != Vector2.ZERO:
		# Send it off to the View Control component.
		Inventory.handle_mouse_input(joystick_look_input)
		View.handle_camera_input(joystick_look_input, get_process_delta_time())
	
	

func _physics_process(delta) -> void:
	gather_input()
	act_on_input(delta)


func gather_joystick_look_input(event: InputEventJoypadMotion) -> void:
	# Joypad motion gives absolute axis values, not relative movement
	# You need to map the right stick axes to your look input
	
	var axis_value = event.axis_value 
	
	# Apply deadzone
	if abs(axis_value) < JOYSTICK_DEADZONE:
		axis_value = 0.0
	
	var axis_raw_value = inverse_lerp(JOYSTICK_DEADZONE, 1.0, abs(axis_value))
	axis_raw_value = controller_look_curve.sample(axis_raw_value)
	axis_value = axis_raw_value * sign(axis_value)
	
	var degrees_per_unit : float = 0.002
	
	var scaled_input = axis_value * Config.MOUSE_SENSITIVITY * degrees_per_unit
	
	# Map to the correct axis (you'll need to figure out which axis is which)
	match event.axis:
		JOY_AXIS_RIGHT_X:  # Right stick horizontal
			joystick_look_input.x = scaled_input
		JOY_AXIS_RIGHT_Y:  # Right stick vertical
			joystick_look_input.y = scaled_input * 0.66
	

func gather_mouse_input(event: InputEventMouseMotion) -> void:
	# Deform the mouse input to make it viewport size independent.
	var viewport_transform := get_tree().root.get_final_transform()
	mouse_input += event.xformed_by(viewport_transform).relative
	
	var degrees_per_unit : float = 0.0001

	# Modify mouse input based on sensitivity and granularity.
	mouse_input *= Config.MOUSE_SENSITIVITY
	mouse_input *= degrees_per_unit
	
	# Send it off to the View Control component.
	Inventory.handle_mouse_input(mouse_input)
	View.handle_camera_input(mouse_input, get_process_delta_time())


var scroll_hack = false
var was_in_air = false
var time_in_air = 0.0
var noclip_enabled := false

func handle_inventory_input():
	if Input.is_action_just_pressed("pm_tab"):
		pass
		#scroll_hack_enabled = !scroll_hack_enabled
	if Input.is_action_just_released("pm_scrolldown"):
		Inventory.dec_weapon()
	
	if Input.is_action_just_released("pm_scrollup"):
		Inventory.inc_weapon()
	
	var selected_slot = -1
	selected_slot = 0 if Input.is_action_just_pressed("pm_slot1") else selected_slot
	selected_slot = 1 if Input.is_action_just_pressed("pm_slot2") else selected_slot
	selected_slot = 2 if Input.is_action_just_pressed("pm_slot3") else selected_slot
	selected_slot = 3 if Input.is_action_just_pressed("pm_slot4") else selected_slot
	
	if selected_slot != -1:
		Inventory.select_weapon(selected_slot)
		
	attack_input = Input.is_action_pressed("pm_attack")
	alt_attack_input = Input.is_action_pressed("pm_altattack")
	
	reload_input = Input.is_action_pressed("pm_reload")

func handle_use_input():
	if Input.is_action_just_pressed("pm_use"):
		var trace_result = TraceQuery.raycast(View.global_position, View.get_forward(), TraceMask.TRIGGER)
		if not trace_result.is_empty():
			var hit_obj = trace_result.hit_collider
			if hit_obj.has_method("interact"):
				trace_result.hit_collider.interact(Body.Root)

func handle_jumpduck_input():
	var stay_on_ground = not jump_cooldown_timer.is_stopped() and has_jumped
	var jump_pressed = Input.is_action_just_pressed("pm_jump")
	if has_midair_queued:  
		jump_pressed = Input.is_action_pressed("pm_jump")
	
	if not jump_cooldown_timer.is_stopped():
		jump_pressed = false
	
	if Config.AUTOHOP:
		jump_on = Input.is_action_pressed("pm_jump")
	else:
		jump_on = (jump_pressed and not stay_on_ground) \
		and not has_jumped
		
		if Body.is_on_floor() and jump_on:
			Body.Root.player_sounds.play_jump()
		
		if has_midair_queued:
			jump_on = (jump_pressed and not stay_on_ground) \
			and not bunnyhop_timer.is_stopped()
		
		if Input.is_action_just_pressed("pm_jump") and not Body.is_on_floor() and bunnyhop_timer.is_stopped(): 
			if not has_midair_queued:
				bunnyhop_timer.start()
				has_midair_queued = true 

	
	if has_jumped:
		has_jumped = (jump_pressed and not stay_on_ground)
		
	if has_midair_queued:
		has_midair_queued = not Body.is_on_floor()
		
		# because jump is off here and we're queued midair, we
		# can assume the player has held space too long and the timer
		# has stopped.
		if not jump_on:
			has_jumped = true
			jump_cooldown_timer.start()
		elif not has_midair_queued:
			bunnyhop_timer.wait_time = max(0.01, bunnyhop_timer.wait_time * 0.8)
			#print(bunnyhop_timer.wait_time)
	duck_on = Input.is_action_pressed("pm_duck")
	if not Body.is_on_floor():
		time_in_air += get_physics_process_delta_time()
	
	if was_in_air and Body.is_on_floor():
		if time_in_air > 0.5: # sorry bout the magic numbers
			Body.Root.player_sounds.play_landing()
		time_in_air = 0.0
		
	was_in_air = not Body.is_on_floor()
	
func handle_noclip():
	if Input.is_action_pressed("pm_jump"):
		Body.velocity.y = 5.0
	elif Input.is_action_pressed("pm_duck"):
		Body.velocity.y = -5.0
	else:
		Body.velocity.y = 0.0

func gather_input() -> void:
	# Get input strength on the horizontal axes.
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var ix = Input.get_action_raw_strength("pm_moveright") - Input.get_action_raw_strength("pm_moveleft")
	var iy = Input.get_action_raw_strength("pm_movebackward") - Input.get_action_raw_strength("pm_moveforward")
	
	if abs(ix) < JOYSTICK_DEADZONE:
		ix = 0.0
	if abs(iy) < JOYSTICK_DEADZONE:
		iy = 0.0
	
	ix = inverse_lerp(JOYSTICK_DEADZONE, 1.0, abs(ix)) * sign(ix)
	iy = inverse_lerp(JOYSTICK_DEADZONE, 1.0, abs(iy)) * sign(iy)
	
	if noclip_enabled:
		handle_noclip()
	else:
		handle_jumpduck_input()
	# Collect input.
	
	# Do this:
	var input_vector = Vector3(ix, 0, iy)
	var input_magnitude = input_vector.length()
	if input_magnitude > 1.0:
		input_vector = input_vector / input_magnitude  # Only normalize if it exceeds 1.0
	movement_input = input_vector
	
	Move.calculate_movement_vector(movement_input, View.yaw_node.rotation.y)
	
	if Input.is_action_just_pressed("debug_noclip"):
		noclip_enabled = not noclip_enabled
	
	handle_inventory_input()
	handle_use_input()

	
	if Input.is_action_just_pressed("debug_kill"):
		$DeleteSaveTimer.start()
		
	if not $DeleteSaveTimer.is_stopped() and Input.is_action_just_released("debug_kill"):
		var temp_damage = DamageInfo.new()
		temp_damage.damage = 19208
		Body.Root.entity_health.take_damage(temp_damage)
		$DeleteSaveTimer.stop()
	
	
	evade_input = Input.is_action_just_pressed("pm_evade")


	
	# Gather jumping and crouching input.
	#$jump_on = Input.is_action_pressed("pm_jump") if Config.AUTOHOP else Input.is_action_just_pressed("pm_jump")


@export var can_slide = false
@export var is_sliding = false
@export var slide_angle = 0.0
@export var slide_speed = 0.0
@export var prev_slide_pos = Vector3.ZERO
@export var slide_dot_with_down = 0.0
var fall_speed = 0.0
func act_on_input(delta) -> void:
	Inventory.set_fire(attack_input)
	Inventory.set_alt_fire(alt_attack_input)
	Inventory.set_reloading(reload_input)
	
	Body.duck(duck_on)
	
	if slide_speed == null:
		slide_speed = 0.0
	
	
	var on_floor = Body.is_on_floor()
	
	# Check if we are on ground
	if on_floor:
		var flattened_velocity = Body.velocity.slide(Vector3.UP)
		#var flattened_normal = Body.get_floor_normal().slide(Vector3.UP)
		var speed = flattened_velocity.length()
		var floor_angle: float = rad_to_deg(Body.get_floor_angle())
		
		
		var units_speed = speed * 38.87 # to hammewr units for easy brain maths 
		var slowed_down = slide_speed - units_speed > 10.0
		var same_angle = abs(floor_angle - slide_angle) < 2.0
		var slide_dir = Body.global_position - prev_slide_pos
		slide_dot_with_down = slide_dir.normalized().dot(Vector3.DOWN)
		var sliding_down = slide_dot_with_down > 0.0
		if is_sliding and (sliding_down or slowed_down or not same_angle):
			is_sliding = false
			slide_angle = 0.0
			slide_speed = 0.0
			jump_on = true
		
		can_slide = can_speed_slide(units_speed, floor_angle) and not sliding_down
		#print("(%s, %s) -> %s -> %s" % [str(units_speed), str(floor_angle), str(slide_angle), can_slide])
	
		if jump_on or is_sliding or can_slide:
			if can_slide and not is_sliding:
				is_sliding = true
				slide_angle = floor_angle
				slide_speed = units_speed
				
			# Not running friction on ground if you press jump fast enough allows you to preserve all speed.
			if not is_sliding:
				#var floor_normal = Body.get_floor_normal()
				#var fall_dot = floor_normal.dot(Vector3.UP)
				#var fall_lerp = clampf(1.0 - fall_dot, 0.0, 1.0)
				#var mult = lerp(0.0, 1.0, fall_lerp)
				#var floor_normal_flat = floor_normal.slide(Vector3.UP).normalized()
				#Body.apply_impulse(-1 * mult * fall_speed * floor_normal_flat)
				jump()
			# NOTE: This is sort of a band-aid to make bunny-hopping on walkable slopes feel a lot nicer.
			Move.airaccelerate()
			if is_sliding:
				Body.velocity.y -= Config.GRAVITY * delta * Body.gravity_multiplier
				Body.velocity = Body.velocity.slide(Body.get_floor_normal())
			
			has_jumped = not can_slide
			scroll_hack = false
		else:
			
			if false and evade_input and not can_evade and evade_timer.is_stopped():
				#var wishdir = movement_input.rotated(Vector3.UP, View.yaw_node.rotation.y)
				#Body.velocity = wishdir * (Body.Config.MAX_SPEED * 1.5)
				evade_timer.start()
			else:
				can_evade = evade_input
			
			is_sliding = false
			var floor_check_pos = Body.global_position + (Body.velocity * get_physics_process_delta_time())
			floor_check_pos += Vector3.DOWN * 0.5
			var ledge_trace = TraceQuery.raycast(
				floor_check_pos, 
				Vector3.DOWN, 
				TraceMask.WORLD,
				1.25)
			
			var friction_multiplier = 1.0
			var movement_zero = movement_input.is_equal_approx(Vector3.ZERO)
			var wishdir = movement_input.rotated(Vector3.UP, View.yaw_node.rotation.y)
			var movement_backward = wishdir.dot(flattened_velocity.normalized()) < -0.6
			
			if ledge_trace.is_empty() and (movement_zero or movement_backward):
				var friction_scale = inverse_lerp(0.0, Config.MAX_SPEED, speed)
				friction_multiplier = 1.0 + (4.0 * friction_scale)
			
			Move.friction(friction_multiplier)
			
			Move.accelerate()
			
			# Constantly reset the coyote time until you're in the air
			coyote_timer.start()
		prev_slide_pos = Body.global_position
			
	else: 
		
		
		if jump_on and not coyote_timer.is_stopped():
			jump()
		
		Move.airaccelerate()
		is_sliding = false
		if Body.velocity.y < 0.0:
			fall_speed = Body.velocity.y
		else:
			fall_speed = 0.0
	
	if not evade_timer.is_stopped():
		var evade_speedup_time = (evade_timer.time_left / evade_timer.wait_time)
		evade_accel_multiplier = lerp(25.0, 1.0, evade_speedup_time)
	else:
		evade_accel_multiplier = 1.0
	
	can_evade = evade_input

const LARGE_INT = 999999
var lookup_angle_map = {
		0 : 75.0,
		400  : 45.0,
		700  : 12.0,
		900  : 4.0,
		1200 : 2.0,
		LARGE_INT : 2.0
	}
func can_speed_slide(speed, angle) -> bool:

	# name shortened from
	# speed_to_angle_map

	var speed_rough = int(speed)
	if speed_rough in lookup_angle_map:
		return angle >= lookup_angle_map[speed_rough]

	var lower_bound = 0
	var upper_bound = 0
	# find the speed this current speed is between
	for lookup_speed in lookup_angle_map.keys():
		if speed < lookup_speed:
			upper_bound = lookup_speed
			break
		lower_bound = lookup_speed
			
	var speed_ratio = inverse_lerp(lower_bound, upper_bound, int(speed))
	var lerp_angle_calc = lerp(lookup_angle_map[lower_bound], lookup_angle_map[upper_bound], speed_ratio)
	var can_slide_res = angle >= lerp_angle_calc
	
	lookup_angle_map[speed_rough] = lerp_angle_calc
	
	return can_slide_res

func jump():
	coyote_timer.stop()
	fall_speed = 0.0
	Move.jump()

func _on_jump_cooldown_timer_timeout() -> void:
	bunnyhop_timer.wait_time = autohop_time


func _on_delete_save_timer_timeout() -> void:
	SaveManager.delete_state()
	
	var temp_damage = DamageInfo.new()
	temp_damage.damage = 19208
	Body.Root.entity_health.take_damage(temp_damage)
	
