extends Resource

class_name ItemData

@export var item_name: String
@export_multiline var item_description: String
@export var item_image: ImageTexture
@export var item_is_dynamic := false


func get_item_id() -> String:
	var entity_tag = resource_path.get_basename() if not item_is_dynamic else "[DYNAMIC]"
	return item_name + "|" + entity_tag

func get_item_state() -> Dictionary:
	return {}
	
func set_item_state(state_dict: Dictionary):
	item_is_dynamic = state_dict.get("item_is_dynamic", false)
	if item_is_dynamic:
		item_name = state_dict.get("item_name", "")
		item_description = state_dict.get("item_description", "")
		# item_image = <instantiate an image texture and set the image? Maybe that should be lazy somehow?>
	
func reset_item_state() -> void:
	pass
