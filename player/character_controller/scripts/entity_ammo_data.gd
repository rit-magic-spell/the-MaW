extends Node

class_name EntityAmmoData

enum AMMO_TYPE
{
	LIGHT,
	RIFLE,
	BUCKSHOT,
	ENERGY,
	BLOOD
}

@export var base_ammo: Dictionary[AMMO_TYPE, int] = {}
@export var max_ammo : Dictionary[AMMO_TYPE, int] = {}

var current_ammo: Dictionary[AMMO_TYPE, int] = {}


func _ready():
	validate_ammo()
	
func validate_ammo():
	for enum_int in AMMO_TYPE.values():
		var enum_name = AMMO_TYPE.keys()[enum_int]
		if enum_int not in base_ammo:
			push_error("Ammo type [%s] not in base ammo dictionary!" % enum_name)
			continue
		if enum_int not in max_ammo:
			push_error("Ammo type [%s] not in max ammo dictionary!" % enum_name)
			continue
	reset_all_ammo()

func reset_all_ammo():
	for enum_int in AMMO_TYPE.values():
		current_ammo[enum_int] = base_ammo[enum_int]

func add_ammo(ammo_type: AMMO_TYPE, amount: int):
	if current_ammo[ammo_type] >= max_ammo[ammo_type]:
		return false
	
	current_ammo[ammo_type] += amount
	current_ammo[ammo_type] = min(max_ammo[ammo_type], current_ammo[ammo_type])
	return true

func take_ammo(ammo_type: AMMO_TYPE, amount: int = 1) -> bool:
	if current_ammo[ammo_type] < amount:
		return false
		
	current_ammo[ammo_type] -= amount
	return true

func has_ammo(ammo_type: AMMO_TYPE, check_amount: int = 1) -> bool:
	return current_ammo[ammo_type] >= check_amount

func get_ammo_amount(ammo_type):
	return current_ammo[ammo_type]

func get_entity_state():
	return current_ammo.duplicate()

func set_entity_state(state_dict):
	if not state_dict:
		return
	current_ammo = state_dict.duplicate()
