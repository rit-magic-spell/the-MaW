extends Node3D

class_name PlayerSpawnLocation

## This is a lie, teleport the player in this
func spawn_player():
	GameManager.player.set_player_position(global_position)
