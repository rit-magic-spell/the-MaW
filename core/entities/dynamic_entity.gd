extends Node3D

class_name DynamicEntity

const DYNAMIC_ENTITY_GROUP_ID = "DynamicEntity"

var ent_owner: Node3D = null
var resource_scene: PackedScene = null

func _ready():
	add_to_group(DYNAMIC_ENTITY_GROUP_ID)

func setup_entity(e_owner: Node3D, packed_scene: PackedScene):
	ent_owner = e_owner
	resource_scene = packed_scene

## Interrupt whatever action the dynamic entity is peforming.
func interrupt_entity():
	queue_free()

func save_dynamic_entity(game_state: GameState):
	var state = get_entity_state()
	state["resource_scene"] = resource_scene
	#game_state.submit_state(self, state)

func get_entity_state() -> Dictionary:
	return {}
