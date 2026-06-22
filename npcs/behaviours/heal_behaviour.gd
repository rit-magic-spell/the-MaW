extends AIBehaviour

class_name HealBehaviour

enum HEAL_METHOD
{
	## Multiply max health by heal_amount and use this value
	MAX_HEALTH_PERCENT,
	## Add heal_amount directly
	VALUE
}

enum HEAL_TYPE
{
	## Just heal, no overheal. Cap at maximum health.
	HEALTH,
	## Just overheal, no healing. Cap at overheal limit.
	OVERHEAL,
	## Heal until max health, then overheal.
	BOTH
}

@export var heal_type: HEAL_TYPE = HEAL_TYPE.HEALTH
@export var heal_method: HEAL_METHOD = HEAL_METHOD.VALUE

@export var heal_amount := 100.0

func setup_behaviour():
	var heal_value = heal_amount
	var health = npc_owner.entity_health
	
	if heal_method == HEAL_METHOD.MAX_HEALTH_PERCENT:
		heal_value *= health.get_max_health()
	
	match heal_type:
		HEAL_TYPE.HEALTH:
			health.heal(heal_value)
		HEAL_TYPE.OVERHEAL:
			health.overheal(heal_value)
		HEAL_TYPE.BOTH:
			var current_health = health.current_health
			var to_heal = health.get_max_health() - current_health
			health.heal(heal_value)
			if health.is_entity_at_max_health():
				heal_value -= to_heal
				if heal_value > 0.0:
					health.overheal(heal_value)

func tick_frame(_delta: float):
	pass
	
func tick_physics(_delta: float):
	pass
	
func teardown_behaviour():
	pass
