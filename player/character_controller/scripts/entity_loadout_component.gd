extends Node


class_name EntityLoadoutComponent

signal swapped_to(weapon:Weapon)
signal swapped_away(weapon:Weapon)

@export var Body: EntityBodyComponent
@export var View : EntityViewComponent
@export var Camera : PlayerCameraComponent


const MAX_EQUIPPED_WEAPONS = 2
var slot_idx = 0


@export var current_equipped_weapons: Array[Weapon]

@onready var swap_to_timer: Timer  = $"../SwapToTimer"
@onready var swap_away_timer: Timer = $"../SwapAwayTimer"
@onready var inventory_data: EntityInventoryData = $"../Entity Inventory Data"
@onready var ammo_data: EntityAmmoData = $"../Entity Ammo Data"


const INVALID_SLOT = -1
var queued_next_slot: int = INVALID_SLOT

func _ready():
	swap_to_timer.timeout.connect(on_swap_to)
	swap_away_timer.timeout.connect(on_swap_away)
	for i in range(MAX_EQUIPPED_WEAPONS):
		current_equipped_weapons.append(null)


enum WeaponAddResult
{
	NONE,
	ADDED_AMMO,
	ADDED_WEAPON
}

#region Equip/Dequip Weapon from Data

## Equips a given weapon data and "makes it real" by spawning it.
## Note, don't use any ol' weapon data for this! This is intended to be used
## with weapon data that already exists in the internal inventory.
## Not doing so could have funky consequences!!
func equip_weapon(weapon_data: WeaponData, desired_slot: int):
	print("[LOADOUT] - Equipping [%s] in slot [%s]" % [weapon_data.item_name, desired_slot])
	var weapon: Weapon = weapon_data.weapon_scene.instantiate()
	add_child(weapon)
	
	if current_equipped_weapons[desired_slot]:
		var old_wep = current_equipped_weapons[desired_slot]
		print("[LOADOUT] - Dequipping [%s] in slot [%s]" % [old_wep.name, desired_slot])
		dequip_weapon(desired_slot)
		
	current_equipped_weapons[desired_slot] = weapon
	weapon.weapon_data_id = weapon_data.get_item_id()
	
	_setup_weapon(weapon)
	if slot_idx != desired_slot:
		weapon.visible = false


func dequip_weapon(dequip_slot: int):
	var weapon_to_destroy = current_equipped_weapons[dequip_slot]
	if not weapon_to_destroy:
		return
	current_equipped_weapons[dequip_slot] = null
	weapon_to_destroy.queue_free()
	

func has_weapon_equipped(weapon_id: String):
	for weapon in current_equipped_weapons:
		if weapon and weapon.is_weapon_valid() and weapon.get_weapon_data().get_item_id() == weapon_id:
			return true
	return false

#endregion

#region Weapon Input
func handle_mouse_input(rel_mouse_input: Vector2):
	if not get_current_weapon():
		return
	get_current_weapon().handle_mouse_input(rel_mouse_input)
	

func set_fire(active: bool):
	if not get_current_weapon(): 
		return
		
	if active:
		get_current_weapon().start_fire()
	else:
		get_current_weapon().stop_fire()


func set_alt_fire(active: bool):
	if not get_current_weapon(): 
		return
		
	if active:
		get_current_weapon().start_alt_fire()
	else:
		get_current_weapon().stop_alt_fire()


func set_reloading(active: bool):
	if not get_current_weapon(): 
		return
	if active:
		get_current_weapon().start_reload()
	else:
		get_current_weapon().stop_reload()

#endregion

#region Slot Management

func get_current_weapon() -> Weapon: 
	return current_equipped_weapons[slot_idx]

func select_weapon(num):
	if num < 0:
		return
	if num > len(current_equipped_weapons) - 1:
		return
	_set_slot(num)
	
func inc_weapon():
	var idx = (slot_idx + 1) % len(current_equipped_weapons)
	while current_equipped_weapons[idx] == null and idx != slot_idx:
		idx = (idx + 1) % len(current_equipped_weapons)
		
	if idx != slot_idx:
		_set_slot(idx)
	
func dec_weapon():
	var idx = slot_idx - 1
	if idx < 0:
		idx = len(current_equipped_weapons) - 1
	while current_equipped_weapons[idx] == null and idx != slot_idx:
		idx -= 1
		if idx < 0:
			idx = len(current_equipped_weapons) - 1
		
	if idx != slot_idx:
		_set_slot(idx)

func get_empty_slot():
	for idx in range(len(current_equipped_weapons)):
		if not current_equipped_weapons[idx]:
			return idx
	return INVALID_SLOT
	

func _set_slot(new_slot_idx: int):
	if new_slot_idx == slot_idx:
		return
	
	if new_slot_idx < 0:
		new_slot_idx = len(current_equipped_weapons) - 1
	
	new_slot_idx %= len(current_equipped_weapons)
	
	print("[LOADOUT] - Switching to slot [%s]" % new_slot_idx)
	var old_weapon: Weapon = current_equipped_weapons[slot_idx]

	queued_next_slot = new_slot_idx
	if old_weapon and old_weapon.is_weapon_valid() and swap_away_timer.is_stopped():
		if old_weapon.get_current_restrictions().get("lock_weapon_switching", false):
			print("[LOADOUT] - Not allowed to swap away from [%s], cancelling" % old_weapon.name)
			return
		print("[LOADOUT] - Starting swap away timer for weapon [%s]" % old_weapon.name)
		swap_away_timer.wait_time = old_weapon.get_weapon_data().dequip_time
		Camera.play_dequip_animation(old_weapon.get_weapon_data().dequip_time)
		swap_away_timer.start()
	else:
		# If you don't have a weapon in the old slot
		# Just jump straight to equipping a weapon.
		print("[LOADOUT] - No weapon equipped currently, starting equip timer")
		on_swap_away()
	

func _setup_weapon(weapon: Weapon):
	print("[LOADOUT] - Setting up weapon [%s]" % [weapon.name])
	weapon.View = View
	weapon.Camera = Camera
	weapon.Body = Body
	weapon.InventoryData = inventory_data
	weapon.AmmoData = ammo_data
	
	weapon.visible = true
	weapon.reparent(Camera.hand, false)
	var data = weapon.get_weapon_data()
	swap_to_timer.wait_time = data.equip_time
	Camera.play_equip_animation(data.equip_time)
	swap_to_timer.start()
	var hud: PlayerHUD = Body.Root.player_hud
	hud.crosshair_manager.update_crosshair(data.crosshair)

#endregion

#region Swap To / Away From Weapon

func on_swap_to():
	if not get_current_weapon():
		return
		
	print("[LOADOUT] - Enabling current weapon after swap [%s]" % get_current_weapon().name)
	get_current_weapon().enable_weapon()
	
	swapped_to.emit(get_current_weapon())

func on_swap_away():
	if queued_next_slot == INVALID_SLOT:
		return
	
	print("[LOADOUT] - Swapping to queued slot [%s]" % queued_next_slot)
	var old_weapon: Weapon = get_current_weapon()
	if old_weapon:
		print("[LOADOUT] - Disabling old weapon [%s]" % old_weapon.name)
		old_weapon.visible = false
		old_weapon.disable_weapon()
		
	slot_idx = queued_next_slot
	queued_next_slot = INVALID_SLOT
	var new_weapon = get_current_weapon()
	
	if new_weapon == null or not new_weapon.is_weapon_valid():
		print("[LOADOUT] - New weapon [%s] was invalid!" % new_weapon.name if new_weapon else "NULL")
		var hud = Body.Root.player_hud
		hud.crosshair_manager.update_crosshair(CrosshairManager.CROSSHAIR.EMPTY)
		return
	
	_setup_weapon(new_weapon)
	
	swapped_away.emit(old_weapon)
	
#endregion

func reset_all_weapons():
	print("[LOADOUT] - Resetting all weapons")
	for weapon in current_equipped_weapons:
		if not weapon or not weapon.is_weapon_valid():
			return
		
		weapon.get_state_machine()
		
		if not weapon.get_weapon_data().uses_ammo:
			return
			
		weapon.get_weapon_data().current_ammo = weapon.get_weapon_data().max_ammo
		

#region Entity State
func get_entity_state() -> Dictionary:
	print("[LOADOUT] - Collecting loadout state")
	var state = {}
	state["current_slot_idx"] = slot_idx
	for idx in range(MAX_EQUIPPED_WEAPONS):
		var state_slot_name = "slot" + str(idx)
		if not current_equipped_weapons[idx]:
			continue
		var slot_weapon = current_equipped_weapons[idx]
		if slot_weapon and slot_weapon.is_weapon_valid():
			
			print("[LOADOUT] - Saving weapon [%s] to slot [%s]" % [slot_weapon.name, state_slot_name])
			state[state_slot_name] = slot_weapon.get_weapon_data().get_item_id()

	return state


func set_entity_state(state_dict):
	print("[LOADOUT] - Restoring loadout state")
	for idx in range(MAX_EQUIPPED_WEAPONS):
		if current_equipped_weapons[idx]:
			current_equipped_weapons[idx].queue_free()
		
		current_equipped_weapons[idx] = null
		var state_slot_name = "slot" + str(idx)
		if state_slot_name not in state_dict:
			continue
		var weapon_id = state_dict[state_slot_name]
		var weapon_data = inventory_data.get_item(weapon_id)
		if not weapon_data:
			push_error("Failed to load weapon with id [%s]! It should be in the inventory already right?" % weapon_id)
			continue
		print("[LOADOUT] - Equipping weapon [%s] to slot [%s]" % [weapon_data.item_name, state_slot_name])
		equip_weapon(weapon_data, idx)
	
	var temp_slot_idx = state_dict.get("current_slot_idx", 0)
	_set_slot(temp_slot_idx)
	var hud = Body.Root.player_hud
	if get_current_weapon() and get_current_weapon().is_weapon_valid():
		hud.crosshair_manager.update_crosshair(get_current_weapon().get_weapon_data().crosshair)
	else:
		hud.crosshair_manager.update_crosshair(CrosshairManager.CROSSHAIR.EMPTY)
#endregion
