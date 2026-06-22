@icon("res://core/node_icons/RedPlus.svg")

extends Node

class_name EntityHealthComponent

## The base health of a given entity.
## Does not change! Use max_health_mod to apply
## changes to the maximum health.
@export_range(0.0, 99999.0) var base_health: float

## How much overheal you get is a multiplier based
## on your maximum health.
## 0.0 = No overheal, 1.0 = Equal to maximum health
@export_range(0.0, 100.0) var max_overheal: float = 0.0

## The time it should take for one point of overheal to decay
@export_range(0.0, 100.0) var overheal_decay: float = 1.0

## How much different types of damage effect the health component. 
# 0.0 - Resist 0% of damage.
# 1.0 - Resist 100% of damage.
@export var resistances: Dictionary[DamageInfo.DAMAGE_TYPE, float]

var modifiers: Array[Callable] = []


var current_health: float
var current_overheal: float

## Additional, or negative, modifier for max health.
## This is added directly to the base health to calculate the new value.
var max_health_mod: float = 0.0

signal on_taken_damage(damage_info: DamageInfo)
signal on_death


func _ready():
	current_health = base_health
	if not Engine.is_editor_hint():
		apply_to_hitboxes()
	
	
func apply_to_hitboxes():
	var hitboxes = Util.get_child_nodes_of_type(get_parent(), Hitbox)
	for hitbox in hitboxes:
		hitbox.set_entity_health(self)


func _physics_process(delta):
	if current_overheal > 0.0:
		current_overheal -= delta * overheal_decay
	else:
		current_overheal = 0.0

func heal(amount: float):
	current_health += amount
	if current_health > get_max_health():
		current_health = get_max_health()

func overheal(amount: float):
	current_overheal += amount
	var max_overheal_amount = get_max_health() * max_overheal
	if current_overheal > max_overheal_amount:
		current_overheal = max_overheal_amount

func heal_with_overheal(amount: float):
	current_health += amount
	var remaining = max(0.0, current_health - get_max_health())
	if remaining > 0.0:
		current_health = get_max_health()
		overheal(remaining)
	
	

func take_damage(damage_info: DamageInfo):
	var final_damage_info = damage_info
	for modifier in modifiers:
		final_damage_info = modifier.call(final_damage_info)
	
	
	var damage = final_damage_info.damage
	# Apply any resistances
	var resistance = 1.0
	if damage_info.damage_type in resistances:
		resistance = resistances[damage_info.damage_type]
		resistance = 1.0 - clampf(resistance, 0.0, 1.0)
		
	damage *= resistance
	
	# Process overheal
	if current_overheal > 0.0:
		current_overheal -= damage
		if current_overheal <= 0.0:
			damage = abs(current_overheal)
			current_overheal = 0.0
		else:
			damage = 0.0
		
	var died = false
	# If you still have damage you can take after overheal, process it.
	if damage > 0.0:
		current_health -= damage
		if current_health <= 0.0:
			died = true
			current_health = 0.0
		
	on_taken_damage.emit(damage_info)
	
	if died:
		on_death.emit()

func kill():
	current_health = 0.0
	current_overheal = 0.0
	on_death.emit()

func reset_health():
	current_health = get_max_health()
	current_overheal = 0.0

func get_max_health():
	return base_health + max_health_mod

func add_max_health(health_amt):
	max_health_mod += health_amt

func sub_max_health(health_amt):
	max_health_mod -= health_amt
	if get_max_health() < current_health:
		var diff = current_health - get_max_health()
		overheal(diff)
		current_health = get_max_health()

## Add a function to modify any incoming damage
## Expecting: func(DamageInfo) -> DamageInfo
func add_modifier(callable: Callable):
	var fake_damage_info = DamageInfo.new()
	var test = callable.call(fake_damage_info)
	if test is not DamageInfo:
		push_error("Invalid modifier!")
		return false
		
	modifiers.append(callable)
	return true

func remove_modifier(callable: Callable):
	var first_idx = modifiers.find(callable)
	if first_idx == -1:
		push_warning("Tried to remove non-existant modifier!")
		return false
	
	modifiers.remove_at(first_idx)
	return true

func is_entity_dead():
	return current_health <= 0.0 and current_overheal <= 0.0

func is_entity_at_max_health():
	return current_health == get_max_health() 

## STATE MANAGEMENT

const STORED_VARS = [
	"current_health",
	"current_overheal", 
	"base_health",
	"max_health_mod"
]

func get_entity_state():
	return Util.serialize_to_dict(self, STORED_VARS)
	
func set_entity_state(state_dict):
	Util.deserialize_from_dict(self, state_dict)
