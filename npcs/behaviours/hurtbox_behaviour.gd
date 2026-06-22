extends AIBehaviour

class_name HurtboxBehaviour


@export var damage: DamageInfo
@export_node_path("Area3D") var hurtbox_paths: Array[NodePath]

var hit_bodies = []

func setup_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tSetting up Hurtbox behaviour!")
	for hurtbox_path in hurtbox_paths:
		var hurtbox = action_owner.get_node(hurtbox_path) as Area3D
		hurtbox.collision_layer = TraceMask.PLAYER | TraceMask.NPC
		hurtbox.collision_mask = TraceMask.PLAYER | TraceMask.NPC
		hurtbox.set_deferred("monitoring", true)
		hurtbox.body_entered.connect(handle_intersect)
	
func tick_physics(_delta: float):
	pass
	
func tick_frame(_delta: float):
	pass
	
func teardown_behaviour():
	if action_owner.ai_sequence.ai_sequencer.debug_sequencer:
		print("\t\t\t\tTearing down Hurtbox behaviour!")
	for hurtbox_path in hurtbox_paths:
		var hurtbox = action_owner.get_node(hurtbox_path) as Area3D
		hurtbox.set_deferred("monitoring", false)
		hurtbox.body_entered.disconnect(handle_intersect)
	hit_bodies.clear()

func handle_intersect(body: Node3D):
	if Util.is_node_child_of(body, npc_owner):
		return
	
	if body in hit_bodies:
		return
		
	hit_bodies.append(body)
	if body is EntityBodyComponent:
		var player: Player = body.Root
		player.entity_health.take_damage(damage)
		
	if body is NPCBase:
		body.entity_health.take_damage(damage)
