extends Node

class_name EntityInventoryComponent

@export var Body: EntityBodyComponent
@export var View : EntityViewComponent
@export var Camera : PlayerCameraComponent

@export var debug_weapons: Array[WeaponData]

@onready var entity_loadout_component: EntityLoadoutComponent = $"Entity Loadout Component"
@onready var entity_inventory_data: EntityInventoryData = $"Entity Inventory Data"
@onready var entity_ammo_data: EntityAmmoData = $"Entity Ammo Data"

func _ready():
	entity_loadout_component.Body = Body
	entity_loadout_component.View = View
	entity_loadout_component.Camera = Camera


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("debug_idkfa"):
		_handle_debug()

var debug_handled := false
func _handle_debug():
	if debug_weapons and not debug_handled:
		for data in debug_weapons:
			if not data:
				continue
			add_item(data)
		debug_handled = true

func add_item(item_data: ItemData):
	#print("[INVENTORY] - Adding item [%s]" % item_data.item_name)
	entity_inventory_data.add_item(item_data)
	if item_data is WeaponData:
		_try_equip_weapon(item_data)

func has_dynamic_item(item_name):
	var item_id = item_name + "|[DYNAMIC]" ## TODO - This should be a constant somewhere
	var in_storage = entity_inventory_data.has_item(item_id)
	return in_storage

func has_item(item_data: ItemData, check_equipped_items = true):
	var id = item_data.get_item_id()
	var in_storage = entity_inventory_data.has_item(id)
	var in_equipment = check_equipped_items and entity_loadout_component.has_weapon_equipped(id) 
	
	return in_storage or in_equipment

func _try_equip_weapon(weapon_data: WeaponData) -> bool:
	var next_empty_slot = entity_loadout_component.get_empty_slot()
	if next_empty_slot == EntityLoadoutComponent.INVALID_SLOT:
		#print("[INVENTORY] - Failed to equip weapon [%s], full inventory!" % [weapon_data.item_name])
		return false
	#print("[INVENTORY] - Equipping weapon [%s] in slot [%s]" % [weapon_data.item_name, next_empty_slot])
	entity_loadout_component.equip_weapon(weapon_data, next_empty_slot)
	return true

func clear_inventory():
	var items = entity_inventory_data.get_items_from_category(EntityInventoryData.ITEM_CATEGORY.ALL)
	for item in items:
		entity_inventory_data.remove_item(item.get_item_id())
	
	for i in range(entity_loadout_component.MAX_EQUIPPED_WEAPONS):
		entity_loadout_component.dequip_weapon( i)
	

#region Loadout Passthrough

func handle_mouse_input(rel_mouse_input: Vector2):
	entity_loadout_component.handle_mouse_input(rel_mouse_input)

func set_fire(active: bool):
	entity_loadout_component.set_fire(active)

func set_alt_fire(active: bool):
	entity_loadout_component.set_alt_fire(active)
	
func set_reloading(active: bool):
	entity_loadout_component.set_reloading(active)

func select_weapon(num):
	entity_loadout_component.select_weapon(num)
	
func inc_weapon():
	entity_loadout_component.inc_weapon()
	
func dec_weapon():
	entity_loadout_component.dec_weapon()

#endregion

func get_entity_state() -> Dictionary:
	#print("[INVENTORY] - Collecting inventory state")
	var state = {}
	state["loadout"] = entity_loadout_component.get_entity_state()
	state["data"] = entity_inventory_data.get_entity_state()
	state["ammo"] = entity_ammo_data.get_entity_state()
	return state
	
func set_entity_state(state_dict: Dictionary):
	entity_inventory_data.set_entity_state(state_dict.get("data", {}))
	entity_loadout_component.set_entity_state(state_dict.get("loadout", {}))
	entity_ammo_data.set_entity_state(state_dict.get("ammo", {}))
