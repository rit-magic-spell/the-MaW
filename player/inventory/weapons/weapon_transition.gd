extends Resource
class_name WeaponTransition


enum CONDITION_TYPE {
	FIRE_PRESSED,
	FIRE_NOT_PRESSED,
	ALT_FIRE_PRESSED, 
	ALT_FIRE_NOT_PRESSED,
	RELOAD_PRESSED,
	RELOAD_NOT_PRESSED,
	AMMO_EMPTY,
	AMMO_NOT_EMPTY,
	AMMO_NOT_FULL,
	AMMO_FULL,
	ANIMATION_FINISHED,
	ANIMATION_NOT_FINISHED,
	
	FIRE_JUST_PRESSED,
	ALT_FIRE_JUST_PRESSED,
	RELOAD_JUST_PRESSED,
	
	PERSISTENT_COUNTER_EMPTY,
	PERSISTENT_COUNTER_NOT_EMPTY,
	PERSISTENT_COUNTER_NOT_FULL,
	PERSISTENT_COUNTER_FULL,
	
	CUSTOM_A,
	CUSTOM_B,
	CUSTOM_C,
	CUSTOM_D,
	
	## Is the weapon active (equipped)?
	WEAPON_ACTIVE,
	## Is the weapon not active (dequipped)?
	WEAPON_NOT_ACTIVE,
	
	INV_HAS_AMMO,
	INV_NO_AMMO
}


@export var target_state: String
@export var conditions: Array[CONDITION_TYPE]



func should_transition(weapon: Weapon) -> bool:
	for condition in conditions:
		if not evaluate(condition, weapon):
			return false
	return true


func evaluate(condition: CONDITION_TYPE, weapon: Weapon) -> bool:
	var data = weapon.get_weapon_data()
	if not data:
		return false
	
	match condition:
		CONDITION_TYPE.FIRE_PRESSED:
			if weapon.get_state_machine().enable_debug and weapon.is_firing:
				print("\tIS_FIRING")
			return weapon.is_firing
		CONDITION_TYPE.FIRE_NOT_PRESSED:
			if weapon.get_state_machine().enable_debug and not weapon.is_firing:
				print("\tIS_NOT_FIRING")
			return not weapon.is_firing
		CONDITION_TYPE.ALT_FIRE_PRESSED:
			if weapon.get_state_machine().enable_debug and weapon.is_alt_firing:
				print("\tIS_ALT_FIRING")
			return weapon.is_alt_firing  
		CONDITION_TYPE.ALT_FIRE_NOT_PRESSED:
			if weapon.get_state_machine().enable_debug and not weapon.is_alt_firing:
				print("\tIS_NOT_ALT_FIRING")
			return not weapon.is_alt_firing
		CONDITION_TYPE.RELOAD_PRESSED:
			if weapon.get_state_machine().enable_debug and weapon.is_reloading:
				print("\tIS_RELOADING")
			return weapon.is_reloading
		CONDITION_TYPE.RELOAD_NOT_PRESSED:
			if weapon.get_state_machine().enable_debug and not weapon.is_reloading:
				print("\tIS_NOT_RELOADING")
			return not weapon.is_reloading
		CONDITION_TYPE.AMMO_EMPTY:
			if weapon.get_state_machine().enable_debug and data.current_ammo == 0:
				print("\tIS_AMMO_EMPTY")
			return data.current_ammo == 0
		CONDITION_TYPE.AMMO_NOT_EMPTY:
			if weapon.get_state_machine().enable_debug and data.current_ammo > 0:
				print("\tAMMO_NOT_EMPTY")
			return data.current_ammo > 0
		CONDITION_TYPE.AMMO_NOT_FULL:
			if weapon.get_state_machine().enable_debug and data.current_ammo < data.max_ammo:
				print("\tAMMO_NOT_EMPTY")
			return data.current_ammo < data.max_ammo
		CONDITION_TYPE.AMMO_FULL:
			if weapon.get_state_machine().enable_debug and data.current_ammo == data.max_ammo:
				print("\tAMMO_FULL")
			return data.current_ammo == data.max_ammo
		CONDITION_TYPE.ANIMATION_FINISHED:
			if weapon.get_state_machine().enable_debug and not weapon.util_anim_playing():
				print("\tANIMATION_FINISHED")
			return not weapon.util_anim_playing()
		CONDITION_TYPE.ANIMATION_NOT_FINISHED:
			if weapon.get_state_machine().enable_debug and weapon.util_anim_playing():
				print("\tANIMATION_PLAYING")
			return weapon.util_anim_playing()
		CONDITION_TYPE.FIRE_JUST_PRESSED:
			if weapon.get_state_machine().enable_debug and weapon.just_started_firing:
				print("\tJUST_FIRED")
			return weapon.just_started_firing
			
		CONDITION_TYPE.ALT_FIRE_JUST_PRESSED:
			if weapon.get_state_machine().enable_debug and weapon.just_started_alt_firing:
				print("\tJUST_ALT_FIRED")
			return weapon.just_started_alt_firing
		CONDITION_TYPE.RELOAD_JUST_PRESSED:
			return weapon.just_started_reloading
		
		CONDITION_TYPE.PERSISTENT_COUNTER_EMPTY:
			return data.persistent_counter <= data.persistent_counter_min
		CONDITION_TYPE.PERSISTENT_COUNTER_NOT_EMPTY:
			return data.persistent_counter > data.persistent_counter_min
		CONDITION_TYPE.PERSISTENT_COUNTER_NOT_FULL:
			return data.persistent_counter < data.persistent_counter_max
		CONDITION_TYPE.PERSISTENT_COUNTER_FULL:
			return data.persistent_counter == data.persistent_counter_max
		
		CONDITION_TYPE.WEAPON_ACTIVE:
			return weapon.is_weapon_active()
		CONDITION_TYPE.WEAPON_NOT_ACTIVE:
			return not weapon.is_weapon_active()
			
		CONDITION_TYPE.INV_HAS_AMMO:
			return weapon.AmmoData.has_ammo(data.ammo_type)
		CONDITION_TYPE.INV_NO_AMMO:
			return not weapon.AmmoData.has_ammo(data.ammo_type)
		
		CONDITION_TYPE.CUSTOM_A:
			if weapon.get_state_machine().enable_debug and weapon.get_custom_var_a():
				print("CUSTOM_A")
			return weapon.get_custom_var_a()
		CONDITION_TYPE.CUSTOM_B:
			if weapon.get_state_machine().enable_debug and weapon.get_custom_var_b():
				print("CUSTOM_B")
			return weapon.get_custom_var_b()
		CONDITION_TYPE.CUSTOM_C:
			push_error("Forgot to implement me, dumbass!")
		CONDITION_TYPE.CUSTOM_D:
			push_error("Forgot to implement me, dumbass!")
		
	return false
