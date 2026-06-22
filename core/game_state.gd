extends Resource

class_name GameState

@export var world_data: Dictionary = {}

func submit_state(id: String, entity_state: Dictionary):
	world_data[id] = entity_state

func retrieve_state(id: String):
	return world_data.get(id, {})

func set_dict(dict: Dictionary):
	world_data = dict

func get_dict() -> Dictionary:
	return world_data
