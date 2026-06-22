extends ItemData

class_name WeaponData

enum ATTACK_TYPE
{
	HITSCAN,
	PROJECTILE_A,
	PROJECTILE_B
}

@export var weapon_scene: PackedScene
@export var crosshair: CrosshairManager.CROSSHAIR = CrosshairManager.CROSSHAIR.EMPTY

@export var uses_ammo: bool = true
@export var max_ammo: int = 6
@export var current_ammo: int = 6
@export var ammo_type: EntityAmmoData.AMMO_TYPE = EntityAmmoData.AMMO_TYPE.LIGHT

@export var equip_time: float = 0.2
@export var dequip_time: float = 0.1

@export var base_spread_deg := 0.0
@export var alt_spread_deg := 0.0

@export var base_attack_type := ATTACK_TYPE.HITSCAN
@export var alt_attack_type := ATTACK_TYPE.HITSCAN

@export var base_pellet_count := 1
@export var alt_pellet_count := 1

@export var base_damage_info: DamageInfo
@export var alt_damage_info: DamageInfo

## How much does the gun push up the crosshair when firing?
@export var recoil_vertical: float = 1.0
## How much does the gun push the crosshair left/right when firing?
@export var recoil_horizontal: float = 0.5

## What's the maximum angle the weapon can kick back in the player's hand?
@export var recoil_hand_angle: float = 50.0

## How much force is applied to the player's hand on each kick?
@export var recoil_hand_kick: float = 0.25

## Useful for effects, like having combo effects for weapons.
## Added originally to give slam firing some extra oomf
@export var persistent_counter: int = 0
@export var persistent_counter_min: int = 0
@export var persistent_counter_max: int = 7


func get_item_state():
	var state = {}
	state["current_ammo"] = current_ammo
	return state

func set_item_state(state_dict: Dictionary):
	current_ammo = state_dict.get("current_ammo", max_ammo)
	
