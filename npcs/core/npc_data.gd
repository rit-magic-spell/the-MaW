extends Resource

class_name NPCData
@export_group("Base Data")
@export var npc_name: String = "None"
@export var max_speed = 1.0
@export var field_of_view = 80.0


#region Pressure and Posture
@export_group("Pressure and Posture")
## Per second, how much pressure should heal?
@export var pressure_heal_rate := 5.0
@export var min_pressure_heal_rate := 0.125
@export var current_pressure_heal_rate := 0.125
## Pressure effects _what_ stun animation plays,
## but not _when_ a stun animation plays. 
@export var current_pressure_value := 0.0
## Anything less than a stun is a flinch
## Anything greater than this value is a stun
## Unless it's a stagger
@export var stun_threshold := 30.0
@export var stagger_threshold := 50.0

## Posture is a THIRD health bar.
## Posture damage heals significantly faster than pressure
## But the cap is much smaller.
## If the cap is exceeded, the current pressure value is used to select
## an animation and posture AND pressure reset. 
@export var max_posture := 25.0
@export var current_posture_value := 25.0
@export var posture_heal_rate := 2.0

@export var accumulated_damage := 0.0

@export_group("Collision Data")
@export var is_on_ground := false
@export var is_against_wall := false
@export var is_approaching_ledge := false
@export var ledge_check_cooldown := 0.0

@export_range(0.01, 60.0) var weight: float = 5.0

@export_group("Status Data")
## How fast should the AI move, on top of existing timescale?
@export var status_speed_multiplier = 1.0

## Is the target ALWAYS visible?
@export var status_target_always_visible = false

@export_group("Serialization Data")
@export var current_position: Vector3
@export var current_rotation: Vector3
@export var home_position: Vector3
@export var home_rotation: Vector3

func get_pressure_interrupt_type():
	if current_pressure_value < stun_threshold:
		return AISequencer.INTERRUPT.FLINCH
	if current_pressure_value < stagger_threshold:
		return AISequencer.INTERRUPT.STUN
	if current_pressure_value > stagger_threshold:
		return AISequencer.INTERRUPT.STAGGER
	return AISequencer.INTERRUPT.FLINCH

func clear_status():
	status_speed_multiplier = 1.0
	status_target_always_visible = false
	current_pressure_heal_rate = pressure_heal_rate
	current_pressure_value = 0.0
	current_posture_value = 0.0
	accumulated_damage = 0.0

func get_entity_state():
	return Util.serialize_to_dict(self)
	
func set_entity_state(state_dict):
	Util.deserialize_from_dict(self, state_dict)
