extends RigidBody3D

class_name WeaponPickup

@export var weapon_data: WeaponData

func setup_pickup():
	var new_weapon: Weapon = weapon_data.weapon_scene.instantiate()
	new_weapon.set_weapon_as_prop()
	add_child(new_weapon)



func _on_pickup_area_body_entered(detected_body: Node3D) -> void:
	if detected_body is not EntityBodyComponent:
		return
	
	var body: EntityBodyComponent = detected_body
	var player: Player = body.Root
	var ammo_type = weapon_data.ammo_type
	var magazine_size = weapon_data.current_ammo
	if player.entity_inventory.entity_loadout_component.has_weapon_equipped(weapon_data.get_item_id()):
		player.entity_inventory.entity_ammo_data.add_ammo(ammo_type, weapon_data.max_ammo)
		queue_free()
	else:
		player.player_input.active_pickup = self




func _on_pickup_area_body_exited(detected_body: Node3D) -> void:
	if detected_body is not EntityBodyComponent:
		return
		
	var body: EntityBodyComponent = detected_body
	var player: Player = body.Root
	if player.player_input.active_pickup == self:
		player.player_input.active_pickup = null


func confirm_pickup(player: Player):
	
	player.entity_inventory.add_item(weapon_data)
	
	var loadout = player.entity_inventory.entity_loadout_component
	var empty_slot = loadout.get_empty_slot()
	if empty_slot != EntityLoadoutComponent.INVALID_SLOT:
		player.entity_inventory._try_equip_weapon(weapon_data)
		loadout.select_weapon(empty_slot)
	else:
		loadout.equip_weapon(weapon_data, loadout.slot_idx)
	queue_free()
