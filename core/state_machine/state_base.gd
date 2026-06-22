@abstract
extends Node
class_name State

@abstract
func enter(entity)

@abstract
func update(entity, dt)

@abstract
func update_slow(entity)

@abstract
func exit(entity)

func get_transitions() -> Array:
	return [
		{
			"next": "Default",
			"condition": func (_entity) -> bool: return false
		}
	]
