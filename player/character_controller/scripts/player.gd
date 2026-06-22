extends Node3D

class_name Player

@onready var entity_body: EntityBodyComponent = $"Entity Body Component"
@onready var entity_inventory: EntityInventoryComponent = $"Entity Inventory Component"
@onready var entity_motion: EntityMotionComponent = $"Entity Motion Component"
@onready var entity_view: EntityViewComponent = $"Entity View Component"
@onready var entity_health: EntityHealthComponent = $"EntityHealthComponent"

@onready var player_camera: PlayerCameraComponent = $"Player Camera Component"
@onready var player_entity: Control = $"Player Entity Monitor"
@onready var player_input: PlayerInputComponent = $"Player Input Component"
@onready var player_hud: PlayerHUD = $"Player Hud Component"
@onready var player_sounds: PlayerAudio = $"Player Camera Component/Player Sounds Component"




@onready var player_hurt_audio: AudioStreamPlayer = $"Player Camera Component/Player Sounds Component/PlayerHurtAudio"


@export var config: EntityConfig

static var player: Player
static func get_player_position() -> Vector3: return player.entity_body.global_position
static func set_player_position(pos: Vector3): player.entity_body.global_position = pos

var initial_rotation: Vector3 = Vector3.ZERO

const MAX_REWINDS = 3
var rewind_count = 0

var base_timeslow_delay = 0.75

func _ready():
	player = self
	if not Engine.is_editor_hint():
		SaveManager.save_requested.connect(save_entity_state)
		SaveManager.load_requested.connect(load_entity_state)
		entity_health.on_death.connect(reset_on_death)
		entity_health.on_taken_damage.connect(on_taken_damage)
	call_deferred("set_player_rotation", initial_rotation)

func set_player_rotation(global_rot: Vector3):
	entity_view.set_player_rotation(global_rot.y + 90.0, global_rot.x)

func _func_godot_apply_properties(properties):
	var angles = properties["angles"]
	initial_rotation = angles

func update_config(new_config: EntityConfig):
	entity_body.Config = new_config
	entity_view.Config = new_config
	player_input.Config = new_config
	entity_motion.Config = new_config

func on_taken_damage(damage_info: DamageInfo):
	var percent_of_health = damage_info.damage / entity_health.get_max_health()
	var decreased_pitch = clamp(lerp(1.0, 0.5, percent_of_health), 0.5, 1.0)
	player_hurt_audio.pitch_scale = decreased_pitch + randf_range(-0.05, 0.05)
	player_hurt_audio.play()
	#player_hud.game_text_manager.submit_text("[DEBUG] Took %s damage" % damage_info.damage)
	




func reset_status():
	entity_inventory.entity_ammo_data.reset_all_ammo()
	entity_inventory.entity_loadout_component.reset_all_weapons()
	entity_health.reset_health()

	

func reset_on_death():
	if player_input.noclip_enabled:
		entity_health.heal(entity_health.get_max_health())
		return
	
	
	for dynamic_entity: DynamicEntity in get_tree().get_nodes_in_group(DynamicEntity.DYNAMIC_ENTITY_GROUP_ID):
		dynamic_entity.queue_free()
		
	GameManager.end_run()

	SaveManager.load_progress()
	
	player_hud.crosshair_manager.handle_reset()
	
	GameManager.start_run(0)


func save_entity_state(game_state: GameState):
	var state = {}
	state["body_state"] = entity_body.get_entity_state()
	state["view_state"] = entity_view.get_entity_state()
	state["inventory_state"] = entity_inventory.get_entity_state()
	state["health"] = entity_health.get_entity_state()
	game_state.submit_state("PLAYER", state)
	
func load_entity_state(game_state: GameState):
	var state_dict = game_state.retrieve_state("PLAYER")
	if not state_dict:
		push_warning("No state dict exists for [PLAYER], using default")
		return
	entity_body.set_entity_state(state_dict.get("body_state", {}))
	entity_view.set_entity_state(state_dict.get("view_state", {}))
	entity_inventory.set_entity_state(state_dict.get("inventory_state", {}))
	entity_health.set_entity_state(state_dict.get("health", {}))
