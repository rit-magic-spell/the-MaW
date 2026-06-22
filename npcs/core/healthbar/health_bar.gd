extends Node3D

## HealthBar for NPCs

@onready var control: Control = $SubViewport/Control
@onready var sprite: Sprite3D = $Sprite3D

@export var npc: NPCBase


func _ready():
	control.set_npc(npc)


func _physics_process(delta: float) -> void:
	if npc.entity_health.is_entity_dead() or npc.entity_health.is_entity_at_max_health():
		sprite.modulate.a = Util.exp_decay(sprite.modulate.a, 0.0, 18, delta)
	else:
		var target_to_npc = npc.world_state.get_vector_to_target() * -1.0
		var target = npc.world_state.target
		if target is EntityBodyComponent:
			var player_forward: Vector3 = target.Root.entity_view.get_forward()
			var dot = player_forward.dot(target_to_npc.normalized())
			var val = inverse_lerp(0.6, 1.0, dot) # magic values I'll be real
			sprite.modulate.a = Util.exp_decay(sprite.modulate.a, val, 18, delta)
	
