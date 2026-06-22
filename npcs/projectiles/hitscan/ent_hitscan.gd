extends DynamicEntity

@export var projectile_speed := 10.0
@export var damage_info: DamageInfo


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
	var hit = TraceQuery.raycast_spread(global_position, direction, 3.0, TraceMask.SOLID)
	handle_hit(hit)

## Interrupt whatever action the dynamic entity is peforming.
func interrupt_entity():
	pass

func handle_hit(hit: TraceQuery.TraceHit):
	if not hit.is_empty() and hit.hit_collider is EntityBodyComponent:
		var ply = hit.hit_collider.Root
		ply.entity_health.take_damage(damage_info)
	
	hit.draw_debug(0.5, Color.YELLOW)


func _on_timer_timeout() -> void:
	queue_free()
