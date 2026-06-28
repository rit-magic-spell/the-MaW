extends Node3D

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
	else:
		## TODO - This is where a UI popup would appear and say "hey, wanna pick up this gun?"
		pass
		
	queue_free()
	
