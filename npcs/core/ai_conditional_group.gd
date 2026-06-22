@tool
extends AICondition

class_name AIConditionGroup

## All conditions in the list must evalute to TRUE
## for the sequence to switch.
@export var conditions: Array[AICondition] = []


func evaluate(world_state: NPCWorldState, action: AIAction):
	for cond in conditions:
		if not cond.evaluate(world_state, action):
			return false
	return true

func _validate_property(property: Dictionary):
	# Show/hide based on variable type
	if property.name != "conditions" and property.name != "sequence_name":
		property.usage = PROPERTY_USAGE_NO_EDITOR
