@tool
extends Area3D

@export var target: String
@export var reset_on: RESET_STYLE

enum RESET_STYLE
{
	ON_EFFIGY,
	ONCE_PER_SAVE
}

var triggered = false
var id: String

func _ready():
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(on_body_enter)
	SaveManager.save_requested.connect(on_save)
	SaveManager.load_requested.connect(on_load)
	id = Util.get_entity_id(self)


func on_body_enter(body):
	if body is not EntityBodyComponent:
		return
	
	if triggered:
		return
	
	LogicManager.fire_target(target, self)
	triggered = true

func handle_reset():
	if reset_on == RESET_STYLE.ON_EFFIGY:
		triggered = false

func on_save(game_state: GameState):
	var state = {}
	state["activated"] = triggered
	game_state.submit_state(id, state)
	
func on_load(game_state: GameState):
	var state = game_state.retrieve_state(id)
	triggered = state.get("activated", false)
