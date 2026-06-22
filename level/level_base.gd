extends Node3D

class_name Level

@export var player_spawn_location : PlayerSpawnLocation

@export var level_progress := 1.0

## Responsible for setting the player location on load
func start_level():
	if not player_spawn_location:
		push_error("Level [%s] does not have a valid player spawn!" % name)
		return
	
	
	player_spawn_location.spawn_player()
	
	
## Responsible for things and stuff
func stop_level():
	pass
