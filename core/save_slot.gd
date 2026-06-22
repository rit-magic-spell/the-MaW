extends Resource

class_name SaveSlot

const SAVE_FILE_PATH = "user://save_slot.tres"

@export var default_state: GameState

## The state of the world, as it exists currently.
## Used for when the game is closed / opened
@export var world_state: GameState

## This saves progress in the world, things that change
## outside of the scope of a save file. Shortcuts, boss kills, etc.
@export var world_progress: GameState

# Initialize all states
func _init():
	default_state = GameState.new()
	world_state = GameState.new()
	world_progress = GameState.new()

func save_to_disk() -> bool:
	var error = ResourceSaver.save(self, SAVE_FILE_PATH)
	if error != OK:
		push_error("Failed to save SaveSlot: ", error_string(error))
		return false
	
	print("SaveSlot saved to: ", SAVE_FILE_PATH)
	return true

static func load_from_disk() -> SaveSlot:
	if not ResourceLoader.exists(SAVE_FILE_PATH):
		print("No save file found at: ", SAVE_FILE_PATH)
		return null
	
	var loaded = ResourceLoader.load(SAVE_FILE_PATH) as SaveSlot
	if loaded == null:
		push_error("Failed to load SaveSlot from: ", SAVE_FILE_PATH)
		return null
	
	return loaded
