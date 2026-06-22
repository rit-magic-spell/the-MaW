extends State
class_name WeaponState

@export var animation_name: String
@export var animation_time: float

enum PITCH_SHIFT_BEHAVIOUR
{
	## Pick a random value between the two pitches
	## set the pitches to be equal for no effect
	RANDOM,
	
	## Every time the weapon is fired,
	## the pitch will increase until it's reloaded
	HIGHER_MAG_EMPTY,
	
	## Every time the weapon is fired,
	## the pitch will increase until it's reloaded
	LOWER_MAG_EMPTY,
	
	HIGHER_COUNTER,
	
	LOWER_COUNTER
}

@export_group("Sound")
@export var state_stream_player: AudioStreamPlayer
@export_range(0.0, 4.0) var state_min_pitch: float = 1.0
@export_range(0.0, 4.0) var state_max_pitch: float = 1.0
@export var pitch_behaviour: PITCH_SHIFT_BEHAVIOUR = PITCH_SHIFT_BEHAVIOUR.RANDOM

@export_group("Input Modifications")
@export var sensitivity_multiplier := 1.0
@export var lock_weapon_switching := false

@export_group("Behaviour")
@export var transitions: Array[WeaponTransition] = []

@export var behaviours: Array[COMMON_BEHAVIOUR]

enum COMMON_BEHAVIOUR
{
	ATTACK,
	ALT_ATTACK,
	CONSUME_SINGLE,
	CONSUME_ALL,
	RELOAD_FULL,
	RELOAD_SINGLE,
	INC_PERSISTENT_COUNTER,
	DEC_PERSISTENT_COUNTER,
	RESET_PERSISTENT_COUNTER,
	RECOIL_BASE,
	RECOIL_ALT,
	BUMP_CROSSHAIR_SCALE,
	SHOW_HINT_SPRITE,
	MUZZLE_FLASH
}
## Consumed right after evaluation, used for 
## detecting "single fire events"
var just_fired = false
var just_alt_fired = true

func enter(weapon: Weapon):
	weapon.play_animation(animation_name, animation_time)
	handle_sound(weapon)
	handle_behaviours(weapon)
	
func update(_weapon, _delta):
	pass
	
func update_slow(_weapon):
	pass
	
func exit(_weapon):
	pass


func get_transitions() -> Array:
	var transition_dicts = []
	for transition in transitions:
		var transition_dict = {}
		transition_dict["next"] = transition.target_state
		var cond = func (weapon: Weapon): return transition.should_transition(weapon)
		transition_dict["condition"] = cond
		transition_dicts.append(transition_dict)
	
	return transition_dicts

func handle_behaviours(weapon: Weapon):
	for behaviour in behaviours:
		match_behaviour(behaviour, weapon)

func handle_sound(weapon: Weapon):	
	if not weapon.is_weapon_active():
		return
	
	if not state_stream_player:
		return
	var pitch = randf_range(state_min_pitch, state_max_pitch)
	var data = weapon.get_weapon_data()
	
	match pitch_behaviour:
		PITCH_SHIFT_BEHAVIOUR.LOWER_MAG_EMPTY:
			var ammo_lerp = float(data.current_ammo) / data.max_ammo
			pitch = lerpf(state_min_pitch, state_max_pitch, ammo_lerp)
		PITCH_SHIFT_BEHAVIOUR.HIGHER_MAG_EMPTY:
			var ammo_lerp = float(data.current_ammo) / data.max_ammo
			pitch = lerpf(state_max_pitch, state_min_pitch, ammo_lerp)
		PITCH_SHIFT_BEHAVIOUR.LOWER_COUNTER:
			var count_lerp = float(data.persistent_counter) / data.persistent_counter_max
			pitch = lerpf(state_min_pitch, state_max_pitch, count_lerp)
		PITCH_SHIFT_BEHAVIOUR.HIGHER_COUNTER:
			var count_lerp = float(data.persistent_counter) / data.persistent_counter_max
			pitch = lerpf(state_max_pitch, state_min_pitch, count_lerp)
	state_stream_player.pitch_scale = pitch
	state_stream_player.play()

	
func match_behaviour(behaviour: COMMON_BEHAVIOUR, weapon: Weapon):
	var data: WeaponData = weapon.get_weapon_data()
	if not data:
		push_error("Weapon [%s] does not have data!" % weapon.name)
		return
	match behaviour:
		COMMON_BEHAVIOUR.ATTACK:
			handle_attack(weapon, false)
		COMMON_BEHAVIOUR.ALT_ATTACK:
			handle_attack(weapon, true)
		COMMON_BEHAVIOUR.CONSUME_SINGLE:
			data.current_ammo -= 1
		COMMON_BEHAVIOUR.RELOAD_SINGLE:
			if weapon.AmmoData.take_ammo(data.ammo_type):
				data.current_ammo += 1
		COMMON_BEHAVIOUR.RELOAD_FULL:
			var needed_ammo = data.max_ammo - data.current_ammo
			var taken_ammo = min(needed_ammo, weapon.AmmoData.get_ammo_amount(data.ammo_type))
			if taken_ammo > 0:
				weapon.AmmoData.take_ammo(data.ammo_type, taken_ammo)
				data.current_ammo += taken_ammo
		COMMON_BEHAVIOUR.INC_PERSISTENT_COUNTER:
			var max_count = data.persistent_counter_max
			data.persistent_counter += 1
			data.persistent_counter = min(max_count, data.persistent_counter)
		COMMON_BEHAVIOUR.DEC_PERSISTENT_COUNTER:
			var min_count = data.persistent_counter_min
			data.persistent_counter -= 1
			data.persistent_counter = max(min_count, data.persistent_counter)
		COMMON_BEHAVIOUR.RESET_PERSISTENT_COUNTER:
			data.persistent_counter = data.persistent_counter_min
		COMMON_BEHAVIOUR.RECOIL_BASE:
			handle_recoil(weapon)
		COMMON_BEHAVIOUR.RECOIL_ALT:
			handle_recoil(weapon)
		COMMON_BEHAVIOUR.BUMP_CROSSHAIR_SCALE:
			var hud = weapon.Body.Root.player_hud
			hud.crosshair_manager.bump_crosshair_scale(2.0)
		COMMON_BEHAVIOUR.SHOW_HINT_SPRITE:
			if weapon.TempHintSprite != null:
				weapon.TempHintSprite.sparkle()
		COMMON_BEHAVIOUR.MUZZLE_FLASH:
			if weapon.MuzzlePosition != null:
				weapon.MuzzlePosition.visible = true

func handle_attack(weapon: Weapon, is_alt: bool):
	var attack_type: WeaponData.ATTACK_TYPE
	var weapon_data = weapon.get_weapon_data()
	if not is_alt:
		attack_type = weapon_data.base_attack_type
	else:
		attack_type = weapon_data.alt_attack_type
	var spread = weapon_data.base_spread_deg if not is_alt else weapon_data.alt_spread_deg
	var pellets = weapon_data.base_pellet_count if not is_alt else weapon_data.alt_pellet_count
	var damage = weapon_data.base_damage_info if not is_alt else weapon_data.alt_damage_info
	match attack_type:
		WeaponData.ATTACK_TYPE.HITSCAN:
			weapon.attack_hitscan(
			spread, 
			pellets, 
			damage)
		WeaponData.ATTACK_TYPE.PROJECTILE_A:
			weapon.attack_projectile()
			

func handle_recoil(weapon: Weapon):
	var data = weapon.get_weapon_data()
	var view_vert = data.recoil_vertical
	var view_hori = data.recoil_horizontal
	var hand_pos  = data.recoil_hand_kick
	var hand_rot  = data.recoil_hand_angle
	weapon.apply_recoil(view_vert, view_hori, hand_pos, hand_rot)
