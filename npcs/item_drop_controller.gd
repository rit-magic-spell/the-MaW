extends Node3D

class_name ItemDropComponent

const WEAPON_PICKUP = preload("uid://by6q32yt6vsik")


@export var loot_table: Dictionary[WeaponData, float]
var drop_id = "NONE"

var dropped = false

func _ready():
	pass

func setup_item_drop(npc_owner: NPCBase):
	npc_owner.entity_health.on_death.connect(try_drop_item)
	drop_id = npc_owner.npc_id + "|ITEM_DROP"

func try_drop_item():
	if not loot_table:
		push_error("Tried to drop weapon with empty loot table!")
		return
	
	if dropped:
		return
	
	var roll = randf()
	for weapon_data in loot_table:
		var chance = loot_table[weapon_data]
		if roll < chance:
			spawn_item(weapon_data)
			return



func spawn_item(weapon_data: WeaponData):
	var weapon_pickup = WEAPON_PICKUP.instantiate()
	add_child(weapon_pickup)
	weapon_pickup.global_position = global_position
	weapon_pickup.weapon_data = weapon_data
	weapon_pickup.setup_pickup()
	dropped = true


func on_save(game_state: GameState):
	var state = {}
	state["has_dropped"] = dropped
	game_state.submit_state(drop_id, state)
	
	
func on_load(game_state: GameState):
	var state = game_state.retrieve_state(drop_id)
	dropped = state["has_dropped"]
