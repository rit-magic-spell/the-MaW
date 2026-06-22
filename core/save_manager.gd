extends Node

enum SAVE_TYPE
{
	DEFAULT,
	WORLD
}

@export var save_slot: SaveSlot

## Fires when a save is requested. A world state is passed
## to the recipient 
signal save_requested(world_state: GameState)
signal load_requested(world_state: GameState)

signal save_progress_requested(world_progress: GameState)
signal load_progress_requested(world_progress: GameState)

func _ready() -> void:
	save_slot = SaveSlot.new()

var ticks = 0

func _physics_process(_delta: float) -> void:
	if ticks == 2:
		save_state(SAVE_TYPE.DEFAULT)
		read_from_file()
	
	ticks += 1
	
	#if ticks % 5 == 0:
		#save_state(SAVE_TYPE.WORLD)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EXIT_TREE:
			save_state(SAVE_TYPE.WORLD)
			write_to_file()

func __get_state_from_save_type(save_type: SAVE_TYPE) -> GameState:
	match save_type:
		SAVE_TYPE.DEFAULT:
			return save_slot.default_state
		SAVE_TYPE.WORLD:
			return save_slot.world_state
	return null

func has_state(save_type: SAVE_TYPE):
	var game_state = __get_state_from_save_type(save_type)
	if not game_state.get_dict():
		return false
	return true

func save_state(save_type: SAVE_TYPE):
	var game_state = __get_state_from_save_type(save_type)
	save_requested.emit(game_state)
	print("Saved: [%s]" % SAVE_TYPE.keys()[save_type])
	
func load_state(save_type: SAVE_TYPE):
	var game_state = __get_state_from_save_type(save_type)
	load_requested.emit(game_state)
	print("Loaded: [%s]" % SAVE_TYPE.keys()[save_type])

func clear_state(save_type: SAVE_TYPE):
	var game_state = __get_state_from_save_type(save_type)
	game_state.set_dict({})

func save_progress():
	var game_state: GameState = save_slot.world_progress
	save_progress_requested.emit(game_state)
	print("Saved: [Progress]")
	
func load_progress():
	var game_state = save_slot.world_progress
	load_progress_requested.emit(game_state)
	print("Loaded: [Progress]")
	
func clear_progress():
	var game_state = save_slot.world_progress
	game_state.set_dict({})

func delete_state():
	clear_state(SAVE_TYPE.WORLD)
	save_slot.world_progress.set_dict({})
	write_to_file()

func write_to_file():
	save_slot.save_to_disk()
	
func read_from_file():
	var temp_save_slot = SaveSlot.load_from_disk()
	if not temp_save_slot:
		return
	var default = save_slot.default_state
	save_slot = temp_save_slot
	save_slot.default_state = default
	load_state(SAVE_TYPE.WORLD)
