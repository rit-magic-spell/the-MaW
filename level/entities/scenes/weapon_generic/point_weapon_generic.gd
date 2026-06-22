@tool
extends Node3D

class_name WeaponPickupGeneric

## TODO - This is a pretty basic class intended mainly for early prototypes
## TODO - God forbid you see this in a final shipped product

var weapon_pickup_id: String
var weapon_data: WeaponData

var mock_weapon: Node3D


const WEAPON_TEST_DATA = preload("uid://bj7ybj265wup8")

const WEAPON_TABLE = [
	WEAPON_TEST_DATA
]

enum SELECTED_WEAPON
{
	PUMP_SHOTGUN,
	THOMPSON,
	REVOLVER,
	BOLT_ACTION
}

@export var selected_weapon: SELECTED_WEAPON = SELECTED_WEAPON.PUMP_SHOTGUN

func _ready():
	_func_godot_build_complete()
	if Engine.is_editor_hint():
		return
	weapon_pickup_id = Util.get_entity_id(self)
	SaveManager.save_requested.connect(on_save)
	SaveManager.load_requested.connect(on_load)
	mock_weapon.set_weapon_as_prop()
	


func _process(delta):
	if Engine.is_editor_hint():
		return
	if visible:
		#DebugDraw3D.draw_text(global_position, "Weapon: [%s]" % weapon_data.item_name, 24, Color.WHITE)
		var debug_a = global_position - (Vector3.ONE * 0.5)
		var debug_b = global_position + (Vector3.ONE * 0.5)
		DebugDraw3D.draw_aabb_ab(debug_a, debug_b, Color.GREEN, delta)

func _physics_process(delta):
	mock_weapon.rotate_y(delta)

func handle_reset():
	pass
	
	#visible = true

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is EntityBodyComponent and visible:
		var ply: Player = body.Root
		var inv = ply.entity_inventory
		if not inv.has_item(weapon_data):
			var loadout = inv.entity_loadout_component
			var equipped_slot = loadout.get_empty_slot()
			inv.add_item(weapon_data)
			if equipped_slot != loadout.INVALID_SLOT:
				loadout._set_slot(equipped_slot)
		else:
			var ammo_type = weapon_data.ammo_type
			var added_ammo = inv.entity_ammo_data.base_ammo[ammo_type]
			inv.entity_ammo_data.add_ammo(ammo_type, added_ammo)
		$WeaponPickupAudio.play()
		visible = false

func _func_godot_apply_properties(properties: Dictionary):
	selected_weapon = properties.get("selected_weapon", 0)

func _func_godot_build_complete():
	weapon_data = WEAPON_TABLE[0]
	var weapon_scene = weapon_data.weapon_scene
	if mock_weapon:
		mock_weapon.queue_free()
	mock_weapon = weapon_scene.instantiate()
	add_child(mock_weapon)
	mock_weapon.global_position = global_position
	
	
	
func on_save(game_state: GameState):
	var state = {}
	state["is_visible"] = visible
	game_state.submit_state(weapon_pickup_id, state)

func on_load(game_state: GameState):
	var state = game_state.retrieve_state(weapon_pickup_id)
	visible = state.get("is_visible", true)
