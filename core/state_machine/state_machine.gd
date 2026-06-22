extends Node

class_name StateMachine
@export var enable_debug: bool = false
@export var starting_state: State
@export var state_machine_owner: Node

var current_state: State

var all_states: Dictionary[String, State]

var enabled = true

func _ready():
	if starting_state == null:
		push_error("No starting state set!")
		
	setup_states()


func setup_states():
	current_state = starting_state
	for child in get_children():
		if child is State:
			all_states[child.name] = child
	current_state.enter(get_parent_entity())

var prev_state = null
func _physics_process(delta):
	if not enabled:
		return
	evaluate_state(delta)


func evaluate_state(delta):
	var transitioned = false
	current_state.update(get_parent_entity(), delta)
	for transition in current_state.get_transitions():
		var transition_cond = transition["condition"]
		if transition_cond.call(get_parent_entity()):
			var next_state = transition["next"]
			if next_state == null:
				var error_message = "Next state was null!\n"
				error_message += "State: " + str(current_state.name) + "\n"
				push_error(error_message)
				next_state = current_state
			var next_state_name = next_state if next_state is String else next_state.name
			current_state.exit(get_parent_entity())
			current_state = all_states[next_state_name]
			current_state.enter(get_parent_entity())
			transitioned = true
			break
	if transitioned and enable_debug and prev_state:
		print("%s: %s -> %s" % [get_parent_entity().name, prev_state.name, current_state.name])
			
	prev_state = current_state

func get_parent_entity():
	return state_machine_owner
