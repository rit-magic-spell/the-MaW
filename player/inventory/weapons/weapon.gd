extends Node3D

class_name Weapon

const HITMARKER = preload("uid://b2hn42bx0an5r")
const WALL_HIT_SPRITE = preload("uid://doyfww2vtw5bw")
const BULLET_TRAIL = preload("uid://vnjr40yeluyf")

@export var View: EntityViewComponent
@export var Camera: PlayerCameraComponent
@export var Body: EntityBodyComponent
@export var InventoryData: EntityInventoryData
@export var AmmoData: EntityAmmoData
@export var MuzzlePosition: Sprite3D
@export var TempHintSprite: Sprite3D

@export var animation_player: AnimationPlayer

@export var weapon_data_id: String

@export var is_firing := false
@export var just_started_firing := false

@export var is_alt_firing := false
@export var just_started_alt_firing := false

@export var is_reloading := false
@export var just_started_reloading := false

var weapon_active := true
var weapon_is_prop := false
var last_mouse_input = Vector2.ZERO

var forced_forward := Vector3.ZERO

var target_rot_x := 0.0
var target_rot_y := 0.0

const CONTROLLER_ASSIST = 0.05

var lazy_state_machine: StateMachine = null
func get_state_machine() -> StateMachine:
	if not lazy_state_machine:
		for child in get_children():
			if child is StateMachine:
				lazy_state_machine = child
				break
	return lazy_state_machine
	
func get_current_state():
	var state_machine = get_state_machine()
	if not state_machine:
		return null
	return state_machine.current_state

func get_weapon_data() -> WeaponData:
	return InventoryData.get_item(weapon_data_id) as WeaponData
	
	
func get_current_restrictions() -> Dictionary:
	var result = {}
	var cur_state = get_current_state()
	
	if cur_state == null:
		return {}
		
	if cur_state is not WeaponState:
		return {}
	
	var wep_state = cur_state as WeaponState
	result["sensitivity_multiplier"] = wep_state.sensitivity_multiplier
	result["lock_weapon_switching"] = wep_state.lock_weapon_switching
	
	return result
	
func get_custom_var_a() -> bool:
	return false

func get_custom_var_b() -> bool:
	return false
	
func get_custom_var_c() -> bool:
	return false
	
func get_custom_var_d() -> bool:
	return false
	
func get_last_mouse_input() -> Vector2:
	return last_mouse_input

func _ready():
	if Engine.is_editor_hint():
		return
		
	call_deferred("_cache_trails")

func _process(delta: float) -> void:
	if weapon_is_prop:
		return
	rotation.y -= last_mouse_input.x * 180.0 * delta
	rotation.x -= last_mouse_input.y * 180.0 * delta
	rotation.y = Util.exp_decay(rotation.y, target_rot_y, 8, delta)
	rotation.x = Util.exp_decay(rotation.x, target_rot_x, 8, delta)
	rotation.y = clampf(rotation.y, -0.5, 0.5)
	rotation.x = clampf(rotation.x, -0.5, 0.5)
	last_mouse_input = Util.exp_decay(last_mouse_input, Vector2.ZERO, 8, delta)
	forced_forward = Vector3.ZERO

func start_fire():
	if not weapon_active or weapon_is_prop:
		return
	just_started_firing = not is_firing and not just_started_firing
	is_firing = true
	
func start_alt_fire():
	if not weapon_active or weapon_is_prop:
		return 
	just_started_alt_firing = not is_alt_firing and not just_started_alt_firing
	is_alt_firing = true
	
func start_reload():
	if not weapon_active or weapon_is_prop:
		return
	just_started_reloading = not is_reloading and not just_started_reloading
	is_reloading = true
	
func stop_fire(): 
	just_started_firing = false
	is_firing = false
	
func stop_alt_fire(): 
	just_started_alt_firing = false
	is_alt_firing = false
	
func stop_reload(): 
	just_started_reloading = false
	is_reloading = false
	
## Set up a "forced" forward vector to center the bullet around.
## Cleared on next physics tick
func set_forced_forward(new_forward: Vector3):
	forced_forward = new_forward
	
func get_forward():
	var result = View.get_forward()
	if forced_forward != Vector3.ZERO:
		result = forced_forward
	return result

func is_weapon_active():
	return weapon_active
	
func is_weapon_valid():
	return get_weapon_data() != null
	
func set_weapon_as_prop():
	weapon_is_prop = true
	get_state_machine().enabled = false
	var visual_instances = Util.get_child_nodes_of_type(self, VisualInstance3D)
	for instance: VisualInstance3D in visual_instances:
		instance.layers = 1
	
func get_muzzle_pos():
	return global_position if not MuzzlePosition else MuzzlePosition.global_position

func handle_mouse_input(movement: Vector2):
	last_mouse_input = movement

func util_any_firing():
	return is_firing or is_alt_firing
	
func util_anim_playing():
	return animation_player.is_playing()
	
func attack_projectile():
	push_error("No attack projectile has been implemented!")
	return
	
	
func attack_hitscan(
	spread: float, 
	hitscan_count: int, 
	damage_info: DamageInfo, 
	assist_angle: float = 0.0):
	
	var ply: Player = GameManager.player
	var input = ply.player_input
	
	if not input.is_using_mouse:
		attack_spherecast(spread, hitscan_count, damage_info, assist_angle, CONTROLLER_ASSIST)
		print("Detected controller! Assisting hitscan!")
		return
	
	var head_pos = View.global_position
	var forward = get_forward()
	var samples: Array[TraceQuery.TraceHit] = []
	if hitscan_count > 1:
		samples.append(TraceQuery.raycast(head_pos, forward, TraceMask.SOLID_FOR_PLAYER))
		for i in range(hitscan_count - 1):
			samples.append(TraceQuery.raycast_spread(head_pos, forward, spread, TraceMask.SOLID_FOR_PLAYER))
	else:
		samples.append(TraceQuery.raycast_spread(head_pos, forward, spread, TraceMask.SOLID_FOR_PLAYER))
			
	_process_attack_samples(samples, damage_info, assist_angle)


func attack_spherecast(spread, count, damage_info, assist_angle, assist_radius):
	var head_pos = View.global_position
	var forward = get_forward()
	var samples: Array[TraceQuery.TraceHit] = []
	
	var random_vectors = []
	for i in range(count):
		random_vectors.append(TraceQuery.get_random_vector_in_cone(head_pos, forward, spread))
			
	var ply: Player = GameManager.player
	var input = ply.player_input
	
	if not input.is_using_mouse:
		print("Detected controller! Assisting spherecast!")
		if assist_radius < CONTROLLER_ASSIST:
			assist_radius = CONTROLLER_ASSIST
		else:
			assist_radius *= 1.25

	for vector in random_vectors:
		var sc_result = TraceQuery.spherecast(head_pos, vector, assist_radius, TraceMask.SOLID_FOR_PLAYER)
		samples.append(_get_best_hit(sc_result))

	_process_attack_samples(samples, damage_info, assist_angle)

func _get_best_hit(samples: Array):
	var max_hitbox: Hitbox = null
	var max_sample := TraceQuery.TraceHit.create_empty(View.global_position, get_forward())
	var sc_len = len(samples)
	if sc_len > 0:
		max_sample = samples[sc_len - 1]
	
	for sample: TraceQuery.TraceHit in samples:
		if sample.hit_collider is Hitbox:
			if not max_hitbox:
				max_hitbox = sample.hit_collider
				max_sample = sample
			elif max_hitbox.damage_multiplier < sample.hit_collider.damage_multiplier:
				max_hitbox = sample.hit_collider
				max_sample = sample
	
	return max_sample

func _process_attack_samples(samples, damage_info, assist_angle):
	damage_info.set_source(View.get_parent())
	
	for sample: TraceQuery.TraceHit in samples:
		if sample.is_empty():
			var end_pos = sample.sample_origin + (sample.sample_direction * 200.0)
			#DebugDraw3D.draw_arrow(sample.sample_origin, end_pos, Color.RED, 0.125, false, 0.5)
			create_trail(get_muzzle_pos(), end_pos)
			continue
		var trail_color = Color.WHITE_SMOKE
		trail_color.a = 0.4
		var hit_obj = sample.hit_collider
		var hit_should_draw = true
		if hit_obj is Hitbox:
			hit_should_draw = _handle_hitbox_hit(sample, assist_angle, damage_info)
		else:
			# Hit a wall or something
			var hit_sprite: Sprite3D = WALL_HIT_SPRITE.instantiate()
			hit_obj.add_child(hit_sprite)
			hit_sprite.global_position = sample.hit_pos
			hit_sprite.global_position += sample.hit_normal * randf_range(0.01, 0.03)
			hit_sprite.look_at(sample.hit_pos + sample.hit_normal)
		
		if hit_should_draw:
			create_trail(get_muzzle_pos(), sample.hit_pos)
			#DebugDraw3D.draw_line(get_muzzle_pos(), sample.hit_pos, trail_color, 0.5)

func _handle_hitbox_hit(sample: TraceQuery.TraceHit, assist_angle: float, damage_info: DamageInfo):
	var head_pos = View.global_position
	var forward = get_forward()
	var hit_obj: Hitbox = sample.hit_collider
	var assist_angled_shot = false
	if assist_angle > 0.0:
		var npc_parent = null
		if hit_obj.hitbox_owner and hit_obj.hitbox_owner is NPCBase:
			npc_parent = hit_obj.hitbox_owner
		
		if npc_parent:
			var hitboxes = npc_parent.get_hitboxes()
			var sample_dir = (sample.hit_pos - head_pos).normalized()
			for hitbox in hitboxes:
				var hitbox_dir = (hitbox.global_position - head_pos).normalized()
				var angle = sample_dir.angle_to(hitbox_dir)
				if angle < deg_to_rad(assist_angle):
					hit_obj = hitbox
					assist_angled_shot = true
					create_trail(get_muzzle_pos(), hit_obj.global_position)
					#DebugDraw3D.draw_line(get_muzzle_pos(), hit_obj.global_position, Color.PURPLE, 0.5)
					break

	hit_obj.process_damage(damage_info)
	var jitter = Vector3(randf(), randf(), randf()) * randf_range(-0.2, 0.2)
	create_hitmarker(sample.hit_pos + jitter, hit_obj, assist_angled_shot)
	
	return not assist_angled_shot


static var cached_trails = []
static var has_setup_trail_cache = false
const INITIAL_TRAIL_CACHE = 100
func create_trail(start_pos: Vector3, end_pos: Vector3):
	var trail = null
	if len(cached_trails) > 0:
		for cached in cached_trails:
			if not cached.is_active():
				trail = cached
				
	if not trail:
		trail = BULLET_TRAIL.instantiate()
		get_tree().root.add_child(trail)
		cached_trails.append(trail)
	var path = (end_pos - start_pos)
	var dir = path.normalized()
	trail.setup(start_pos, dir, path.length())

func _cache_trails():
	if has_setup_trail_cache:
		return
	for i in range(INITIAL_TRAIL_CACHE):
		create_trail(Vector3.ZERO, Vector3.DOWN)
	
	has_setup_trail_cache = true


static var cached_hitmarkers = []
static var has_setup_hitmarkers = false
func create_hitmarker(hit_pos: Vector3, hit_obj: Hitbox, assist_angled_shot = false):
	var hitmarker = null
	if len(cached_hitmarkers) > 0:
		for cached in cached_hitmarkers:
			if not cached.is_active():
				hitmarker = cached
				
	if not hitmarker:
		hitmarker = HITMARKER.instantiate()
		get_tree().root.add_child(hitmarker)
		cached_hitmarkers.append(hitmarker)
	
	hitmarker.global_position = hit_pos if not assist_angled_shot else hit_obj.global_position
	var high_damage_color = Color.RED
	var low_damage_color = Color.NAVY_BLUE
	var dmg_mult = hit_obj.damage_multiplier

	if hit_obj.damage_multiplier > 1.0:
		var lerp_val = inverse_lerp(1.0, 2.0, dmg_mult)
		hitmarker.modulate = lerp(Color.WHITE, high_damage_color, lerp_val)
	else:
		var lerp_val = inverse_lerp(1.0, 0.0, dmg_mult)
		hitmarker.modulate = lerp(Color.WHITE, low_damage_color, lerp_val)
	
	hitmarker.setup_hitmarker()
	

func apply_recoil(view_kick_vertical, view_kick_horizontal, hand_punch_translate, hand_punch_rotate):
	View.add_recoil(view_kick_vertical, view_kick_horizontal)
	Camera.add_weapon_recoil(hand_punch_rotate, hand_punch_translate)

func enable_weapon():
	weapon_active = true
	stop_reload()
	var visual_instances = Util.get_child_nodes_of_type(self, VisualInstance3D)
	for instance: VisualInstance3D in visual_instances:
		instance.layers = 2
	
func disable_weapon():
	stop_fire()
	stop_alt_fire()
	stop_reload()
	weapon_active = false

func play_animation(anim_name: String, duration: float):
	if not animation_player:
		push_error("Forgot to set the animation player on \"" + name + "\"" )
	
	var clip: Animation = animation_player.get_animation(anim_name)
	if not clip:
		push_error("No animation named \"" + anim_name + "\" found!" )
		return
	
	var clip_time = clip.length
	var modifier = clip_time / duration
	animation_player.seek(0.0, true, true)
	animation_player.play(anim_name, -1, modifier)
