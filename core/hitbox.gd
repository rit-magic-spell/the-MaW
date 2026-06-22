extends Area3D

class_name Hitbox

@export_range(0.0, 10.0) var damage_multiplier = 1.0
@export_range(0.0, 10.0) var pressure_multiplier = 1.0
@export_range(0.0, 10.0) var posture_multiplier = 1.0

var entity_health: EntityHealthComponent
var hitbox_owner = null

func _ready():
	#if collision_layer != TraceMask.HITBOX:
		#push_warning("Hitbox [%s] is on an incorrect layer, correcting and moving on." % [name])
	collision_layer = TraceMask.HITBOX
	collision_mask = 0

func set_entity_health(health: EntityHealthComponent):
	entity_health = health

func set_hitbox_owner(hbox_owner):
	hitbox_owner = hbox_owner

func process_damage(damage_info: DamageInfo):
	var mod_damage_info = damage_info.dmg_copy()
	if not entity_health:
		push_error("Hitbox [%s] does not have an attached health!" % [name])
		return
	mod_damage_info.damage *= damage_multiplier
	mod_damage_info.posture_damage *= posture_multiplier
	mod_damage_info.pressure_damage *= pressure_multiplier
	entity_health.take_damage(mod_damage_info)
	
func handle_reset():
	collision_layer = TraceMask.HITBOX
