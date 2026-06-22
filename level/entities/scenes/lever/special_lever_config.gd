@tool
extends Interactable

@export var target: String
@export var required_item := ""
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

@onready var lever_base: Node3D = $".."

var pulled = false
var lever_id: String = ""

@onready var switch_sound: AudioStreamPlayer3D = $"../SwitchSound"
@onready var switch_active_sound: AudioStreamPlayer3D = $"../SwitchActiveSound"
const FAST_CONFIG = preload("uid://4rjce64x4t3n")
const DEFAULT_CONFIG = preload("uid://c1hjc38orbiye")

func _ready():
	if Engine.is_editor_hint():
		return
	SaveManager.save_requested.connect(on_save)
	SaveManager.load_requested.connect(on_load)
	lever_id = Util.get_entity_id(self)
	target = lever_base.target
	required_item = lever_base.required_item

func _process(delta):
	DebugDraw3D.draw_text(global_position + -global_basis.z, "Toggle movement A/B", 12, Color.WHITE, delta)

func interact(player: Player):
	var distance_to_player = player.entity_body.global_position.distance_to(global_position)
	if distance_to_player < 3.0:
		if not pulled:
			if required_item and not player.entity_inventory.has_dynamic_item(required_item):
				player.player_hud.game_text_manager.submit_text("Locked - Requires [%s] to open" % required_item, 3.0)
				switch_sound.play()
				return
				
			animation_player.play("lever_use")
			switch_active_sound.play()
		else:
			animation_player.play("lever_unuse")
			switch_sound.play()

	

func _on_lever_pulled():
	var ply: Player = GameManager.player
	ply.update_config(FAST_CONFIG)
	pulled = true
	
func _on_lever_pushed():
	var ply: Player = GameManager.player
	ply.update_config(DEFAULT_CONFIG)
	pulled = false
	

func handle_reset():
	if not pulled:
		animation_player.play('RESET')

func on_save(game_state: GameState):
	var state = {}
	state["pulled"] = pulled
	game_state.submit_state(lever_id, state)
	
func on_load(game_state: GameState):
	var state = game_state.retrieve_state(lever_id)
	pulled = state.get("pulled", false)
	if pulled:
		animation_player.play("lever_used")
	else:
		animation_player.play('RESET')
	
