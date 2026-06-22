extends AIBehaviour

class_name WeaknessBehaviour

@export_range(0.0, 100.0) var damage_multiplier: float = 1.0
@export_range(0.0, 100.0) var pressure_multiplier: float = 1.0
@export_range(0.0, 100.0) var posture_multiplier: float = 1.0

func setup_behaviour():
	npc_owner.entity_health.add_modifier(modify_damage)

func tick_frame(_delta: float):
	pass
	
func tick_physics(_delta: float):
	pass
	
func modify_damage(damage_info: DamageInfo):
	damage_info.damage *= damage_multiplier
	damage_info.pressure_damage *= pressure_multiplier
	damage_info.posture_damage *= posture_multiplier
	return damage_info


func teardown_behaviour():
	npc_owner.entity_health.remove_modifier(modify_damage)
