extends DynamicEntity

class_name Fireball

@export var projectile_speed := 10.0
@export var damage_info: DamageInfo


@onready var animation_player: AnimationPlayer = $AnimationPlayer

var direction: Vector3
var setup = false
func setup_entity(e_owner: Node3D, packed_scene: PackedScene):
	if e_owner is not NPCBase:
		return
	
	var npc: NPCBase = e_owner
	ent_owner = e_owner
	resource_scene = packed_scene
	
	
	var to_target = npc.world_state.vector_to_target.normalized()
	to_target = (npc.get_target().global_position - global_position).normalized()
	direction = to_target
	setup = true

## Interrupt whatever action the dynamic entity is peforming.
func interrupt_entity():
	pass

func _physics_process(delta: float) -> void:
	if not setup:
		return
	
	var real_delta = delta * Timescale.get_gameplay_timescale()
	var added_velocity = direction * projectile_speed * real_delta
	var next_pos = global_position + added_velocity
	
	# Failsafe
	var trace = TraceQuery.linecast(global_position, next_pos, TraceMask.SOLID_FOR_PLAYER)
	
	if not trace.is_empty() and handle_hit(trace.hit_collider):
		die()
		
	global_position += added_velocity

func handle_hit(collider: CollisionObject3D):
	if TraceMask.is_body_on_tracemask(collider, TraceMask.NPC):
		return false

	if TraceMask.is_body_on_tracemask(collider, TraceMask.HITBOX):
		return false

	if collider is EntityBodyComponent:
		var ply = collider.Root
		ply.entity_health.take_damage(damage_info)
		
	return true
	
func die():
	animation_player.play("die")


func _on_area_3d_body_entered(body: Node3D) -> void:
	var hit = handle_hit(body)
	if hit:
		die()


func _on_timer_timeout() -> void:
	queue_free()
