@abstract

extends ItemData

class_name UseableData

enum USE_STATE
{
	READY,
	DELAY,
	ACTIVE,
	COOLDOWN
}

## How long until the item activates?
@export var use_delay_time: float = 0.1

## How long is the item active?
@export var use_active_time: float = 15.0

## How long until you can use the item again, after using it?
@export var use_cooldown_time: float = 5.0

## How many items are in the stack currently?
@export var current_stack_size = 3

## How many items can the stack hold?
@export var max_stack_size = 3

var item_state: USE_STATE = USE_STATE.READY

var state_timer := 0.0

func use_item(player):
	if item_state != USE_STATE.READY:
		return false
	
	if current_stack_size <= 0:
		return false
	
	item_state = USE_STATE.DELAY
	state_timer = use_delay_time
	_on_item_delay(player)

func tick_item(player: Player, delta: float):
	match item_state:
		USE_STATE.DELAY:
			_tick_delay(player, delta)
		USE_STATE.ACTIVE:
			_tick_active(player, delta)
		USE_STATE.COOLDOWN:
			_tick_cooldown(player, delta)
	
	_on_tick_item(player, delta)

func _tick_delay(player, delta):
	if state_timer <= 0.0:
		item_state = USE_STATE.ACTIVE
		state_timer = use_active_time
		_on_item_active(player)
		return 
		
	state_timer -= delta
	
func _tick_active(player, delta):
	if state_timer <= 0.0:
		item_state = USE_STATE.COOLDOWN
		state_timer = use_cooldown_time
		_on_item_cooldown(player)
		return 
		
	state_timer -= delta
	
func _tick_cooldown(player, delta):
	if state_timer <= 0.0:
		item_state = USE_STATE.READY
		state_timer = 0.0
		_on_item_ready(player)
		return 
		
	state_timer -= delta

func reset_item_state() -> void:
	current_stack_size = max_stack_size
	
## Called when transition occurs: COOLDOWN -> READY
func _on_item_ready(_player: Player):
	pass

## Called when transition occurs: READY -> DELAY
func _on_item_delay(_player: Player):
	pass

## Called when transition occurs: DELAY -> ACTIVE
func _on_item_active(_player: Player):
	pass

## Called when transition occurs: ACTIVE -> COOLDOWN
func _on_item_cooldown(_player: Player):
	pass
	
## Called when equipped on each physics process tick, REGARDLESS OF STATE!
func _on_tick_item(_player: Player, _delta: float):
	pass
