@abstract
extends Resource

class_name AIBehaviour

## The NPC who is controlling this AI behaviour
var npc_owner: NPCBase

## The AIAction this behaviour belongs to.
var action_owner: AIAction

## DO NOT OVERWRITE!
## Called to start a behaviour, which sets up variables for them
func start_behaviour(action: AIAction, npc: NPCBase):
	npc_owner = npc
	action_owner = action
	setup_behaviour()
	

@abstract
func setup_behaviour()

@abstract
func tick_physics(delta: float)

@abstract
func tick_frame(delta: float)

func interrupt_behaviour():
	pass

@abstract
func teardown_behaviour()
