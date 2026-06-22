extends Node


const REALTIME = 0.0
const VERY_FAST = 1.0 / 30.0
const FAST = 1.0 / 10.0
const MEDIUM = 1.0 / 4.0
const SLOW = 1.0 / 2.0
const VERY_SLOW = 1.0
const GLACIAL = 2.5


var registered_entities_process: Dictionary[String, float] = {}
var registered_entities_physics: Dictionary[String, float] = {}

var callable_scheduler_process: Dictionary[String, CallableScheduler] = {}
var callable_scheduler_physics: Dictionary[String, CallableScheduler] = {}

# EDIT: Track RichDeltaCallable objects by entity_id to avoid recreating them for comparisons
var rich_callable_physics: Dictionary[String, RichDeltaCallable] = {}
var rich_callable_process: Dictionary[String, RichDeltaCallable] = {}

class RichDeltaCallable:
	
	var _entity: Node
	var _method_name: String
	
	func _init(entity: Node, method_name: String):
		_entity = entity
		_method_name = method_name

	func call_delta(delta):
		_entity.call(_method_name, delta)




class CallableScheduler:
	var _current_queue_idx := 0
	var _queue := []
	
	var _interval = 0.25
	var _threshold = 0.0
	
	func _init(interval):
		_interval = interval
	
	func tick(delta):
		var queue_len = len(_queue)
		if queue_len <= 0:
			return
		
		if _interval <= 0.0:
			for callable in _queue:
				callable.call_delta(delta)
			return
		
		var calls_to_distribute = queue_len * delta / max(_interval, 0.001)
		_threshold += calls_to_distribute
		
		while _threshold >= 1.0:
			_current_queue_idx %= queue_len
			var callable: RichDeltaCallable = _queue[_current_queue_idx]
			callable.call_delta(_interval)
			_current_queue_idx += 1
			_threshold -= 1.0
		
		
	func add(callable: RichDeltaCallable):
		if _queue.has(callable):
			push_warning("Tried to schedule existing callable twice! [%s]" % callable.get_method())
			return
		_queue.push_back(callable)
	
	func remove(callable: RichDeltaCallable):
		_queue.erase(callable)


func register_physics(entity: Node, entity_id: String, callable: Callable, wait_duration: float):
	var real_duration = snappedf(wait_duration, 0.001)
	
	if registered_entities_physics.has(entity_id):
		var old_duration = registered_entities_physics[entity_id]
		if old_duration == real_duration:
			return
			
		callable_scheduler_physics[str(old_duration)].remove(rich_callable_physics[entity_id])
		
	registered_entities_physics[entity_id] = real_duration
	
	_schedule_physics(entity, entity_id, callable, real_duration)

func register_process(entity: Node, entity_id: String, callable: Callable, wait_duration: float):
	
	var real_duration = snappedf(wait_duration, 0.001)
	
	if registered_entities_process.has(entity_id):
		var old_duration = registered_entities_process[entity_id]
		if old_duration == real_duration:
			return
		callable_scheduler_process[str(old_duration)].remove(rich_callable_process[entity_id])
		
	registered_entities_process[entity_id] = real_duration
	
	_schedule_process(entity, entity_id, callable, real_duration)
	

func unregister_physics(entity: Node, entity_id: String, callable: Callable) -> void:
	var current_duration = registered_entities_physics[entity_id]
	callable_scheduler_physics[str(current_duration)].remove(rich_callable_physics[entity_id])
	rich_callable_physics.erase(entity_id)
	registered_entities_physics.erase(entity_id)
	
func unregister_process(entity: Node, entity_id: String, callable: Callable) -> void:
	var current_duration = registered_entities_process[entity_id]
	callable_scheduler_process[str(current_duration)].remove(rich_callable_process[entity_id])
	rich_callable_process.erase(entity_id)
	registered_entities_process.erase(entity_id)


func _schedule_physics(entity: Node, entity_id: String, callable: Callable, duration: float):
	var scheduler: CallableScheduler
	if not callable_scheduler_physics.has(str(duration)):
		callable_scheduler_physics[str(duration)] = CallableScheduler.new(duration)

	scheduler = callable_scheduler_physics[str(duration)]
	
	var rich_callable = rich_callable_physics.get(entity_id, RichDeltaCallable.new(entity, callable.get_method()))
	rich_callable_physics[entity_id] = rich_callable
	scheduler.add(rich_callable)
	
func _schedule_process(entity: Node, entity_id: String, callable: Callable, duration: float):
	var scheduler: CallableScheduler
	if not callable_scheduler_process.has(str(duration)):
		callable_scheduler_process[str(duration)] = CallableScheduler.new(duration)

	scheduler = callable_scheduler_process[str(duration)]
	
	var rich_callable = rich_callable_process.get(entity_id, RichDeltaCallable.new(entity, callable.get_method()))
	rich_callable_process[entity_id] = rich_callable
	scheduler.add(rich_callable)


func _physics_process(delta: float) -> void:
	for scheduler: CallableScheduler in callable_scheduler_physics.values():
		scheduler.tick(delta)

func _process(delta: float) -> void:
	for scheduler: CallableScheduler in callable_scheduler_process.values():
		scheduler.tick(delta)
