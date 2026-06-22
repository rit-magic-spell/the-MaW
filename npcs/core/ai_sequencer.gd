@icon("res://npcs/node_icons/AISequencerIcon.svg")

extends Node
## Responsible for playing sequences, and handling transitions between them.
class_name AISequencer

@export var debug_sequencer = false

enum INTERRUPT
{
	## Did you just see the player?
	PLAYER_SPOTTED,
	## Did you stop seeing the player?
	PLAYER_LOST,
	## Did you take damage from any source?
	DAMAGE_TAKEN,
	## Is there a projectile that will hit you on the way? Or a melee attack?
	ATTACK_INCOMING,
	## Are you being forced to flinch?
	FLINCH,
	## Are you being forced to a stun animation?
	STUN,
	## Are you being forced to a stagger animation?
	STAGGER,
	## Are you dead? 
	DEATH,
	## Has an ally near you had a player spotted or a player lost?
	ALLY_ALERTED,
	
	## Note: These are constantly fired when the conditions listed are true.
	## This is denoted by the "IS" keyword.
	
	## Are you in the player's crosshair?
	IS_IN_CROSSHAIR,
	## Is the player actively visible?
	IS_PLAYER_VISIBLE,
	VALID_PATH,
	INVALID_PATH,
	
	RESURRECT,
	RESET,
	
	## Are you about to walk off of a ledge?
	APPROACHING_LEDGE
}

@export var npc_owner: NPCBase

@export var global_interrupts: Dictionary[INTERRUPT, String]

var current_sequence_name: String
var prev_sequence_name: String = ""

var sequence_map: Dictionary[String, AISequence] = {}

func _ready():
	update_sequences()
	
func setup_owner(npc: NPCBase):
	npc_owner = npc
	for sequence_name in sequence_map:
		var sequence = sequence_map[sequence_name]
		sequence.setup_owner(npc, self)

func tick_physics(delta):
	if has_current_sequence():
		var modified_delta = delta # Gameplay timescale applied in NPCBase
		modified_delta *= npc_owner.npc_data.status_speed_multiplier
		get_current_sequence().tick_physics(modified_delta)

func tick_frame(delta: float) -> void:
	debug_sequencer = npc_owner.enable_debug
	if has_current_sequence():
		var modified_delta = delta # Gameplay timescale applied in NPCBase
		modified_delta *= npc_owner.npc_data.status_speed_multiplier
		get_current_sequence().tick_frame(modified_delta)


func update_sequences():
	var sequences = Util.get_child_nodes_of_type(self, AISequence)
	for sequence in sequences:
		sequence_map[sequence.name] = sequence


func set_sequence(sequence_name: String):
	if sequence_name not in sequence_map:
		push_error("Tried to play invalid sequence [%s]!" % [sequence_name])
		return
		
	if has_current_sequence():
		var old_sequence = get_current_sequence()
		
		if old_sequence != null:
			old_sequence.end_sequence()
	
	if debug_sequencer:
		print("Setting sequence to: [%s]" % [sequence_name])
		
	prev_sequence_name = current_sequence_name
	current_sequence_name = sequence_name
	get_current_sequence().start_sequence(npc_owner)

func notify_sequence_reached_end():
	# By default, if a sequence runs dry and no next sequence has been set, 
	# replay the current sequence
	var sequence: AISequence = get_current_sequence()
	sequence.end_sequence()
	prev_sequence_name = current_sequence_name
	if debug_sequencer:
		print("Sequence restarted, setting previous sequence to [%s]" % prev_sequence_name)
	sequence.restart_sequence(npc_owner)
	

func handle_interrupt(interrupt: INTERRUPT):
	if not has_current_sequence():
		return
	
	var current_sequence = get_current_sequence()
	
	if not current_sequence.should_interrupt(interrupt):
		return
	
	var next_sequence = current_sequence.get_custom_interrupt_sequence(interrupt)
	
	# Process interrupts in the order of:
	# Custom -> Global
	if not next_sequence:
		if interrupt in global_interrupts:
			next_sequence = global_interrupts[interrupt]
		else:
			# If you don't have a valid sequence in either the global table
			# or the custom interrupt table, drop it.
			return
			
	var candidates = next_sequence.split(";")
	var candidates_cleaned = []
	for candidate in candidates:
		#print(candidate)
		candidates_cleaned.append(candidate.strip_edges())

	next_sequence = candidates_cleaned.pick_random()
	# Because we checked should_interrupt as a guard clause,
	# there should always be a next sequence to jump to.
	#get_current_sequence().interrupt_sequence()
	if debug_sequencer:
		print("\tInterrupting sequence [%s] with [%s]" % [current_sequence_name, INTERRUPT.keys()[interrupt]])
	
	get_current_sequence().interrupt_sequence()
	prev_sequence_name = current_sequence_name
	current_sequence_name = next_sequence
	get_current_sequence().start_sequence(npc_owner)


func has_current_sequence():
	return current_sequence_name and not current_sequence_name.is_empty()

func get_current_sequence():
	return sequence_map[current_sequence_name]


func get_entity_state():
	var state_dict = {}
	state_dict["current_sequence_name"] = current_sequence_name
	state_dict["prev_sequence_name"] = prev_sequence_name
	state_dict["current_sequence_state"] = get_current_sequence().get_entity_state()
	return state_dict
	
func set_entity_state(state_dict):
	if not state_dict:
		return
	set_sequence(state_dict["current_sequence_name"])
	prev_sequence_name = state_dict.get("prev_sequence_name", "")
	get_current_sequence().set_entity_state(state_dict["current_sequence_state"])
