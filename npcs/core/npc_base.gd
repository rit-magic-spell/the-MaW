@tool
extends CharacterBody3D
class_name NPCBase

# Responsible for movement ONLY
@export var animation_player: AnimationPlayer
@export var ai_sequencer: AISequencer
@export var entity_health: EntityHealthComponent
@export var item_dropper: ItemDropComponent
@export var visibility_notifier: VisibleOnScreenNotifier3D

@export var starting_sequence: String

@export var npc_data: NPCData

@export var world_state: NPCWorldState
@export var nav_agent: NavigationAgent3D

@export var eye_position: Node3D

@export var enable_debug := false

## Velocity that will be consumed when an agent moves
## Intended for use with MovementBehaviour
var queued_velocity: Vector3 = Vector3.ZERO

var npc_id: String

var hitboxes = []
var meshes = []

func _ready():
	if Engine.is_editor_hint():
		return
	
	if entity_health == null:
		push_error("NPC has no health component!")
		return
	
	if ai_sequencer == null:
		push_error("NPC has no AI Sequencer!")
		return
		
	if animation_player == null:
		push_error("NPC has no animation player!")
		return
	

	world_state = NPCWorldState.new()
	
	if nav_agent == null:
		nav_agent = NavigationAgent3D.new()
		add_child(nav_agent)
	
	npc_id = Util.get_entity_id(self)
	
	npc_data = npc_data.duplicate_deep(Resource.DEEP_DUPLICATE_INTERNAL)
	npc_data.home_position = global_position
	npc_data.home_rotation = global_rotation
	
	entity_health.on_taken_damage.connect(handle_damage)
	entity_health.on_death.connect(handle_death)
	
	if not item_dropper:
		push_warning("NPC [%s] has no item dropper assigned!" % name)
	else:
		item_dropper.setup_item_drop(self)
	
	SaveManager.save_requested.connect(save_entity_state)
	SaveManager.load_requested.connect(load_entity_state)
	
	hitboxes = Util.get_child_nodes_of_type(self, Hitbox)
	for hitbox in hitboxes:
		hitbox.set_hitbox_owner(self)
	hitboxes.sort_custom(func (a, b): return a.damage_multiplier > b.damage_multiplier)
	
	meshes = Util.get_child_nodes_of_type(self, MeshInstance3D)
	
	ai_sequencer.call_deferred("setup_owner", self)
	ai_sequencer.call_deferred("set_sequence", starting_sequence)
	
	TickScheduler.register_process(self, npc_id, _tick_process, TickScheduler.REALTIME)
	TickScheduler.register_physics(self, npc_id, _tick_physics, TickScheduler.REALTIME)


var tick_speeds = [
	TickScheduler.REALTIME,
	TickScheduler.REALTIME,
	TickScheduler.VERY_FAST,
	TickScheduler.VERY_FAST,
	TickScheduler.FAST,
	TickScheduler.MEDIUM,
	TickScheduler.SLOW,
	TickScheduler.VERY_SLOW
]

var visible_tick_speeds = [
	TickScheduler.REALTIME,
	TickScheduler.REALTIME,
	TickScheduler.REALTIME,
	TickScheduler.REALTIME,
	TickScheduler.VERY_FAST,
	TickScheduler.VERY_FAST,
	TickScheduler.VERY_FAST,
	TickScheduler.FAST,
	TickScheduler.FAST,
	TickScheduler.MEDIUM
]

@onready var player: Player = GameManager.player

func _physics_process(_delta: float) -> void:
	_update_ticked_functions()

func _update_ticked_functions():
	if Engine.is_editor_hint():
		return
	var slowtick_distance = 2.0 if entity_health.is_entity_dead() else 5.0
	var dist_to_ply = player.get_player_position().distance_to(global_position)
	var tick_speed = dist_to_ply / slowtick_distance

	
	var speeds = tick_speeds if not is_npc_visible() else visible_tick_speeds
	
	var speed_idx = floori(max(0.0, tick_speed))
	speed_idx = min(len(speeds) - 1, speed_idx)
	
	if not npc_data.is_on_ground:
		speed_idx = 0

	TickScheduler.register_process(self, npc_id, _tick_process, speeds[speed_idx])
	TickScheduler.register_physics(self, npc_id, _tick_physics, speeds[speed_idx])

func _tick_process(delta):
	var real_delta = Timescale.get_gameplay_timescale() * delta
	real_delta *= npc_data.status_speed_multiplier
	ai_sequencer.tick_frame(real_delta)

func _tick_physics(delta: float) -> void:
	var real_delta = Timescale.get_gameplay_timescale() * delta
	real_delta *= npc_data.status_speed_multiplier
	_process_pressure(real_delta)
	_process_posture(real_delta)
	_process_world_state(real_delta)
	_process_movement(real_delta)
	
	ai_sequencer.tick_physics(real_delta)
	
	npc_data.accumulated_damage -= real_delta * 15.0
	if npc_data.accumulated_damage <= 0.0:
		npc_data.accumulated_damage = 0.0
	
	#if world_state.is_target_visible():
		#DebugUtil.draw_resource_values(world_state, global_position + Vector3.UP)
	#DebugDraw3D.draw_text(global_position + (Vector3.UP * 1.5), str(snapped(npc_data.accumulated_damage, 0.1)))
	npc_data.current_position = global_position
	npc_data.current_rotation = global_rotation
	
	#DebugDraw3D.draw_sphere(global_position + (Vector3.UP * 1.25), 0.125, Color.CYAN, get_process_delta_time())
	
	
	## TODO - REMOVE ME!
	if Input.is_action_pressed("debug_aggro"):
		if entity_health.is_entity_dead():
			fire_interrupt(AISequencer.INTERRUPT.RESURRECT)
		npc_data.status_target_always_visible = true


func _process_pressure(delta):
	npc_data.current_pressure_value -= delta * npc_data.current_pressure_heal_rate
	npc_data.current_pressure_heal_rate += delta * 3.0
	if npc_data.current_pressure_heal_rate > npc_data.pressure_heal_rate:
		npc_data.current_pressure_heal_rate = npc_data.pressure_heal_rate
		
	if npc_data.current_pressure_value < 0.0:
		npc_data.current_pressure_value = 0.0
	

var last_health: float = 1000.0
func _process_posture(delta):
	npc_data.current_posture_value += delta
	if npc_data.current_posture_value < 0.0:
		_handle_posture_break()
	elif npc_data.current_posture_value > npc_data.max_posture:
		npc_data.current_posture_value = npc_data.max_posture 
	last_health = entity_health.current_health

func _handle_posture_break():
	var interrupt_type = npc_data.get_pressure_interrupt_type()
	if not interrupt_type:
		push_error("No valid interrupt type for posture break???")
		return
		
	var health_mult = entity_health.current_health / entity_health.base_health
	npc_data.current_posture_value = npc_data.max_posture * health_mult
	npc_data.current_pressure_value = 0.0
	var temp_damage = DamageInfo.new()
	temp_damage.damage = npc_data.accumulated_damage * 0.1
	match interrupt_type:
		AISequencer.INTERRUPT.STUN:
			temp_damage.damage = npc_data.accumulated_damage * 0.5
		AISequencer.INTERRUPT.STAGGER:
			temp_damage.damage = npc_data.accumulated_damage
	#print("Adding [%s] generic damage on posture break." % snapped(temp_damage.damage, 0.01))
	npc_data.accumulated_damage = 0.0
	entity_health.take_damage(temp_damage)
	ai_sequencer.handle_interrupt(interrupt_type)
	
	


var stuck_fails = 0
func _process_world_state(delta: float):
	# Just reduce world hits when you're dead for now
	world_state.sample_world(self, global_position, get_target(), delta)
	
	if world_state.is_target_just_visible():
		fire_interrupt(AISequencer.INTERRUPT.PLAYER_SPOTTED)
	if world_state.is_target_visible() or world_state.is_target_visibility_remembered():
		fire_interrupt(AISequencer.INTERRUPT.IS_PLAYER_VISIBLE)
	if world_state.is_target_just_lost():
		fire_interrupt(AISequencer.INTERRUPT.PLAYER_LOST)
	
	if world_state.is_target_reachable():
		fire_interrupt(AISequencer.INTERRUPT.VALID_PATH)
	elif nav_agent.is_navigation_finished():
		#var warp_point = find_nearest_nav_point(global_position)
		#global_position = warp_point
		#if warp_point != global_position:
		fire_interrupt(AISequencer.INTERRUPT.INVALID_PATH)
	
	#var forward = -transform.basis.z
	#var right = transform.basis.x * 1.25
	#DebugUtil.draw_resource_values(world_state, global_position + forward + right + Vector3.UP)

var gravity = 1.0
var prev_dist_to_target: float = 0.0
var distance_stuck_count := 0
const DISTANCE_CONSIDERED_STUCK = 0.1
var downwarp_timer = 0.0

func _process_movement(delta: float):
	velocity.x = queued_velocity.x
	velocity.z = queued_velocity.z
		
	
	if not npc_data.is_on_ground:
		velocity.y -= gravity
	else:
		velocity.y = queued_velocity.y
	
	var downwarp_trace = TraceQuery.raycast(global_position, Vector3.DOWN, TraceMask.WORLD)
	if downwarp_trace.is_empty():
		downwarp_timer += delta
		if downwarp_timer > 2.5:
			entity_health.kill()
		return
	
	
	downwarp_timer = 0.0
		
	var ledge_trace_pos = global_position + (velocity * delta) + (Vector3.UP * 0.1)
	var ledge_trace = TraceQuery.raycast(ledge_trace_pos, Vector3.DOWN, TraceMask.SOLID_FOR_NPC)
	npc_data.is_approaching_ledge = ledge_trace.is_empty() or ledge_trace.hit_distance > (1.0 + 2.0)
	
	#if npc_data.is_approaching_ledge:
		#ledge_trace.draw_debug(delta, Color.RED)
	#else:
		#ledge_trace.draw_debug(delta, Color.WHITE)
	
	if npc_data.is_approaching_ledge:
		fire_interrupt(AISequencer.INTERRUPT.APPROACHING_LEDGE)
	
	var collision = move_and_collide(velocity * delta)
	var rid = collision.get_collider_rid() if collision else RID()
	var registered_colliders = {}
	var on_ground = false
	var against_wall = false
	while collision != null and not registered_colliders.get(rid, 0) > 5:
		velocity = velocity.slide(collision.get_normal())
		rid = collision.get_collider_rid()
		if not registered_colliders.has(rid):
			registered_colliders[rid] = 0
		registered_colliders[rid] += 1
		
		var collider = collision.get_collider()
		if collider is EntityBodyComponent:
			collider.apply_impulse(
				collision.get_normal() * \
				collider.Config.MAX_SPEED * \
				-1 * npc_data.weight * delta)
		
		var dot_with_up = collision.get_normal().dot(Vector3.UP)
		var dot_with_right = collision.get_normal().dot(Vector3.RIGHT)
		if dot_with_up > 0.7:
			on_ground = true
		
		if abs(dot_with_up) < 0.25:
			against_wall = true
		
		collision = move_and_collide(velocity * delta)
	
		
	npc_data.is_on_ground = on_ground
	npc_data.is_against_wall = against_wall
	
	queued_velocity = Vector3.ZERO
	prev_dist_to_target = world_state.get_distance_to_target()


func submit_velocity(added_velocity: Vector3, weight: float = 1.0):
	queued_velocity += added_velocity * weight

func get_next_vector_to_target(target_position: Vector3):
	nav_agent.target_position = target_position
	if nav_agent.is_navigation_finished():
		return Vector3.ZERO
		
	var path_pos = nav_agent.get_next_path_position()
	
	return (path_pos - global_position).normalized()

func find_nearest_nav_point(start_pos: Vector3, max_radius: float = 3.0, steps: int = 8) -> Vector3:
	# First check current position
	if nav_agent.is_target_reachable():
		return start_pos
	
	var starting_pos = global_position
	# Search in expanding circles
	var radius_step = max_radius / steps
	var search_rings = []
	for i in range(steps):
		search_rings.append((i + 1) * radius_step)
		
	for search_radius in search_rings:
		#print("Searching radius [%s]" % search_radius)
		for angle_step in range(0, 360, 45):  # 8 directions per circle
			var angle = deg_to_rad(1.0 * angle_step)
			var test_pos = start_pos + Vector3(cos(angle) * search_radius, 0, sin(angle) * search_radius)
			#DebugDraw3D.draw_sphere(test_pos, 0.05, Color.RED)
			var mesh_rid = nav_agent.get_navigation_map()
			var nav_point = NavigationServer3D.map_get_closest_point(mesh_rid, test_pos)
			var path: PackedVector3Array = NavigationServer3D.map_get_path(
				mesh_rid,
				nav_point,
				nav_agent.target_position,
				true  # optimize
			)
			if not path:
				continue
			
			var last_path_pos = path.get(path.size() - 1)
			var distance_to_last = nav_agent.target_position.distance_to(last_path_pos)
			if distance_to_last < nav_agent.target_desired_distance:
				NavigationServer3D.agent_set_position(nav_agent.get_rid(), starting_pos)
				return nav_point
				
	# Fallback to original position
	return start_pos

var target_override: Node3D = null
func set_target_override(node: Node3D):
	target_override = node

func clear_target_override():
	target_override = null

func get_target() -> Node3D:
	if target_override:
		return target_override
	
	var ply: Player = GameManager.player
	return ply.entity_body

func get_forward() -> Vector3:
	return basis.z.normalized()

func get_eye_position() -> Vector3:
	return global_position if not eye_position else eye_position.global_position

## Returns cached hitbox list on an enemy, sorted from highest damage to lowest.
func get_hitboxes():
	return hitboxes
	
func get_meshes():
	return meshes

func is_npc_visible():
	return not visibility_notifier or visibility_notifier.is_on_screen()

func fire_interrupt(interrupt: AISequencer.INTERRUPT):
	ai_sequencer.handle_interrupt(interrupt)

func handle_death():
	fire_interrupt(AISequencer.INTERRUPT.DEATH)
	npc_data.clear_status()
	#var hitboxes = Util.get_child_nodes_of_type(self, Hitbox)
	#for hitbox in hitboxes:
		#hitbox.collision_layer = TraceMask.TRIGGER
	collision_layer = TraceMask.TRIGGER
	#Timescale.slow_global_time(0.01, 5.0)
	

var last_damage_taken = DamageInfo.new()
func handle_damage(damage_info: DamageInfo):
	last_damage_taken = damage_info
	npc_data.accumulated_damage += damage_info.damage
	fire_interrupt(AISequencer.INTERRUPT.DAMAGE_TAKEN)
	npc_data.current_pressure_value += damage_info.pressure_damage
	npc_data.current_pressure_heal_rate = npc_data.min_pressure_heal_rate
	npc_data.current_posture_value -= damage_info.posture_damage

func _func_godot_apply_properties(entity_properties: Dictionary):
	var angle = entity_properties.get("angle")
	var rot_vec = Vector3.ZERO
	rot_vec.y = angle# + 45.0
	rotation_degrees = rot_vec

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		return
	TickScheduler.unregister_physics(self, npc_id, _tick_physics)
	TickScheduler.unregister_process(self, npc_id, _tick_process)


func handle_reset():
	fire_interrupt(AISequencer.INTERRUPT.RESET)
	collision_layer = TraceMask.NPC
	npc_data.clear_status()
	npc_data.current_position = npc_data.home_position
	npc_data.current_rotation = npc_data.current_rotation
	world_state.clear_world()
	entity_health.reset_health()
	global_position = npc_data.home_position
	global_rotation = npc_data.home_rotation


func draw_debug_text(delta):
	var above_head = global_position + (Vector3.UP * 1.25)
	var debug_text = "Health: %s / %s\n"
	debug_text += "Pressure: %s (-%s / sec) [%s]\n"
	debug_text += "Posture: %s / %s (+%s / sec)\n"
	
	
	debug_text += "Current Action: %s\n"
	var action_str = ""
	if ai_sequencer.has_current_sequence():
		var current_action = ai_sequencer.get_current_sequence().get_current_action() 
		action_str = current_action.name if current_action else "NULL"
	var interrupt = npc_data.get_pressusre_interrupt_type()
	var interrupt_str = AISequencer.INTERRUPT.keys()[interrupt]
	
	
	debug_text %= [
		snapped(entity_health.current_health, 0.1), 
		snapped(entity_health.base_health, 0.1),
		snapped(npc_data.current_pressure_value, 0.1),
		snapped(npc_data.current_pressure_heal_rate, 0.1),
		interrupt_str,
		snapped(npc_data.current_posture_value, 0.1),
		snapped(npc_data.max_posture, 0.1),
		snapped(npc_data.posture_heal_rate, 0.1),
		action_str
	]
	
	DebugDraw3D.draw_text(above_head, debug_text, 20, Color.WHITE)

func save_entity_state(game_state: GameState):
	var state_dict = {}
	state_dict["sequencer_state"] = ai_sequencer.get_entity_state()
	state_dict["health_state"] = entity_health.get_entity_state() 
	state_dict["npc_world_state"] = world_state.get_entity_state()
	state_dict["npc_data"] = npc_data.get_entity_state()
	game_state.submit_state(npc_id, state_dict)
	
func load_entity_state(game_state: GameState):
	var state_dict = game_state.retrieve_state(npc_id)
	if not state_dict:
		push_warning("No state dict exists for [%s], using default" % npc_id)
		return
	
	entity_health.set_entity_state(state_dict["health_state"])
	world_state.set_entity_state(state_dict["npc_world_state"])
	npc_data.set_entity_state(state_dict["npc_data"])
	
	ai_sequencer.set_entity_state(state_dict["sequencer_state"])
	
	global_position = npc_data.current_position
	global_rotation = npc_data.current_rotation
