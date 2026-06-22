extends Area3D

@export var target: String
@export var refire_time: float
@export var trigger_style: TRIGGER_STYLE

enum TRIGGER_STYLE
{
	ONCE_PER_ENTRANCE,
	CONSTANT
}

var triggered = false
var id: String

var player_tracked = false

var timer: float = 0.0
func _ready():
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(on_body_enter)
	body_exited.connect(on_body_exit)
	SaveManager.save_requested.connect(on_save)
	SaveManager.load_requested.connect(on_load)
	id = Util.get_entity_id(self)

## TODO - Right now this only operates as a constant trigger
## more functionality needs to be added.

func _physics_process(delta: float) -> void:
	
	if not player_tracked:
		timer = 0.0
		return
	
	timer += delta
	if timer > refire_time:
		timer = 0.0
		LogicManager.fire_target(target, self)
	

func on_body_enter(body):
	if body is not EntityBodyComponent:
		return
	player_tracked = true
	

func on_body_exit(body):
	if body is not EntityBodyComponent:
		return
	player_tracked = false

func on_save(game_state: GameState):
	var state = {}
	state["activated"] = triggered
	game_state.submit_state(id, state)
	
func on_load(game_state: GameState):
	var state = game_state.retrieve_state(id)
	triggered = state.get("activated", false)
