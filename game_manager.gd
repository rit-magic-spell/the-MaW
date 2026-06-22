extends Node

@export var biomes: Array[String]


@export var biome_level_data: Dictionary[String, BiomeData]


@export var player: Player

const PLAYER_SCENE = preload("uid://gwunh0jnqjjk")

var biome_progress: float = 0.0

var current_biome_idx := 0
var current_level_idx := 0

var current_run_seed := 0

var active_level: Level = null

const BIOME_THRESHOLD := 3.0

const GAME_MANAGER_ID := "GAME_STATE"


func _ready() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	start_run()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


## Responsible for resetting player attributes
## Responsible for setting player level to first area
## Reset any progress indicators
func start_run(seed = 0):
	current_run_seed = seed
	player.reset_status()
	_setup_next_level()

func load_next_level():
	_update_progress(get_current_level().level_progress)
	_update_level_idx()
	_setup_next_level()

func end_run():
	current_biome_idx = 0
	current_level_idx = 0
	current_run_seed = 0
	player.entity_inventory.clear_inventory()

func get_active_biome() -> String:
	return biomes[current_biome_idx]

func get_active_biome_levels() -> Array:
	return biome_level_data[get_active_biome()].levels
	
func get_current_level_scene() -> PackedScene:
	return get_active_biome_levels()[current_level_idx]
	
func get_current_level() -> Level:
	return active_level

func set_current_level(level: Level):
	active_level = level

func _update_progress(added_progress: float):
	biome_progress += added_progress
	if biome_progress > BIOME_THRESHOLD:
		current_biome_idx += 1

	if current_biome_idx >= len(biomes):
		push_warning("Current biome index exceeds maximum! [%s] Resetting!" % current_biome_idx)
		current_biome_idx %= len(biomes)

func _setup_next_level():

	show_loading_screen()
	
	# Clear out the previous level
	if get_current_level():
		get_current_level().stop_level()
		active_level.queue_free()
	
	# Get the next level scene, not instantiated yet
	var next_level_scene = get_current_level_scene()
	
	# Instantiate the next level
	var pre_active_level = next_level_scene.instantiate()
	
	add_child(pre_active_level)
	
	set_current_level(pre_active_level)
	
	# Using the helper, start the level
	get_current_level().start_level()
	
	hide_loading_screen()


func _update_level_idx():
	var seeded_rand = rand_from_seed(current_run_seed)
	var next_seed = rand_from_seed(seeded_rand[0])
	
	current_run_seed = next_seed[0]
	
	var next_level_idx = seeded_rand[0] % len(get_active_biome_levels())
	
	current_level_idx = next_level_idx


func show_loading_screen():
	pass
	
func hide_loading_screen():
	pass
	
func on_save(world_state: GameState):
	var state = {}
	state["biome_progress"] = biome_progress
	state["current_biome_idx"] = current_biome_idx
	state["current_level_idx"] = current_level_idx
	state["current_seed"] = current_run_seed
	world_state.submit_state(GAME_MANAGER_ID, state)
	
func on_load(world_state: GameState):
	var state = world_state.retrieve_state(GAME_MANAGER_ID)
	biome_progress = state.get("biome_progress", 0.0)
	current_biome_idx = state.get("current_biome_idx", 0)
	current_level_idx = state.get("current_level_idx", 0)
	current_run_seed = state.get("current_run_seed", 0)
	
	
