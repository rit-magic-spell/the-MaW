extends Node

class_name EntityInventoryData

enum ITEM_CATEGORY
{
	## Represents weapon data
	WEAPON,
	## Represents usable data
	USEABLE,
	## Represents trinket data
	TRINKET,
	## Represents generic data (keys, generic items, etc)
	GENERIC,
	## Returns all item data
	ALL
}

var stored_items: Dictionary[String, ItemData] = {}

func add_item(item: ItemData):
	stored_items[item.get_item_id()] = item
	
func get_item(item_id: String) -> ItemData:
	return stored_items.get(item_id, null)

func has_item(item_id: String) -> bool:
	return stored_items.has(item_id)

func remove_item(item_id: String):
	var item = get_item(item_id)
	if not item:
		push_error("Tried to delete item [%s] that doesn't exist!" % item_id)
		return
	
	if item.item_is_dynamic and item.item_image: # If we have an image instantiated, delete it.
		item.item_image.queue_free()
	
	
	# Items are ref counted, so I think as long as we destroy all our references
	# to it it's fine to just erase.
	stored_items.erase(item_id)

func get_items_from_category(item_category: ITEM_CATEGORY) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for item in stored_items.values():
		if __compare_item_to_category(item, item_category):
			result.append(item)
	return result

func __compare_item_to_category(item, item_category):
	match item_category:
		ITEM_CATEGORY.WEAPON:
			return item is WeaponData
		ITEM_CATEGORY.USEABLE:
			return item is UseableData
		ITEM_CATEGORY.TRINKET:
			return false ## TODO - add trinkets
		ITEM_CATEGORY.GENERIC:
			return item is ItemData and item is not WeaponData and item is not UseableData
	return true


func debug_string():
	var weapons = get_items_from_category(EntityInventoryData.ITEM_CATEGORY.WEAPON)
	var useables = get_items_from_category(EntityInventoryData.ITEM_CATEGORY.USEABLE)
	var items = get_items_from_category(EntityInventoryData.ITEM_CATEGORY.GENERIC)
	
	__print_item_list("WEAPONS", weapons)
	__print_item_list("ITEMS", items)
	
	
func __print_item_list(list_name, item_list):
	print("%s:" % list_name)
	var items_str = "["
	for weapon in item_list:
		items_str += "  %s" % weapon.get_item_id() 
	items_str += "  ]"
	print(items_str)

func get_entity_state():
	print("[DATA] - Collecting inventory data")
	var state = {}
	var all_items = get_items_from_category(ITEM_CATEGORY.ALL)
	for item in all_items:
		var item_id = item.get_item_id()
		state[item_id] = item.get_item_state()
		state[item_id]["item_is_dynamic"] = item.item_is_dynamic
		
		if item.item_is_dynamic:
			state[item_id]["item_name"] = item.item_name
			state[item_id]["item_description"] = item.item_description
			state[item_id]["item_picture_path"] = item.item_image.resource_path if item.item_image else ""
		else:
			state[item_id]["item_path"] = item.resource_path
	
	return state
	
func set_entity_state(state_dict: Dictionary):
	print("[DATA] - Restoring inventory data")
	var old_item_ids = stored_items.keys()
	var new_item_ids = state_dict.keys()
	
	var items_to_remove = old_item_ids.filter(func(item_id): return item_id not in new_item_ids)
	var items_to_update = new_item_ids.filter(func(item_id): return item_id in old_item_ids)
	var items_to_add = new_item_ids.filter(func(item_id): return item_id not in old_item_ids)

	for remove_id in items_to_remove:
		remove_item(remove_id)
	
	for existing_id in items_to_update:
		var existing_item = get_item(existing_id)
		existing_item.set_item_state(state_dict[existing_id])
	
	for new_id in items_to_add:
		var item_state = state_dict[new_id]
		var new_item: ItemData
		if item_state["item_is_dynamic"]:
			new_item = ItemData.new()
			new_item.set_item_state(item_state)
		else:
			new_item = load(state_dict[new_id]["item_path"])
		add_item(new_item)
		
	print(debug_string())
