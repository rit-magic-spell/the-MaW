extends Node3D

const RAYCAST_DISTANCE = 9999.0
const DISTRIBUTION_FLATNESS = 0.5
const ENABLE_HITSCAN_DEBUG = false
const HITSCAN_DISPLAY_TIME = 2.0

@onready var sphere_shape = SphereShape3D.new()

class TraceHit:
	var sample_origin: Vector3 = Vector3.ZERO
	var sample_direction: Vector3 = Vector3.ZERO
	var hit_pos: Vector3 = Vector3.ZERO
	var hit_normal: Vector3 = Vector3.ZERO
	var hit_collider: CollisionObject3D = null
	var hit_distance: float = 0.0
	var hit_empty = false

	static func create_empty(origin: Vector3, direction: Vector3) -> TraceHit:
		var hit = TraceHit.new(origin, Vector3.ZERO, Vector3.ZERO, null, 0.0)
		hit.sample_direction = direction
		return hit

	func is_empty():
		return hit_empty

	func draw_debug(draw_time: float, color = Color.WHITE):
		if is_empty():
			DebugDraw3D.draw_sphere(sample_origin, 0.125, color, draw_time)
			return
		DebugDraw3D.draw_line(sample_origin, hit_pos, color, draw_time)
		

	func _init(origin, pos, norm, ent, dist):
		sample_origin = origin
		hit_pos = pos
		hit_normal = norm
		sample_direction = (hit_pos - sample_origin).normalized()
		
		hit_collider = ent
		hit_distance = dist
		if not hit_collider:
			hit_empty = true
			
	func _to_string() -> String:
		if hit_empty:
			return "TraceHit[EMPTY]"
		var out = "TraceHit[pos: %s, norm: %s, collider: %s, dist: %s]"
		out %= [hit_pos, hit_normal, hit_collider, hit_distance]
		return out

func raycast(origin: Vector3, direction: Vector3, mask: int = TraceMask.SOLID, max_distance: float = RAYCAST_DISTANCE) -> TraceHit:
	var end_pos = origin + (direction.normalized() * max_distance)
	return linecast(origin, end_pos, mask)

func get_random_vector_in_cone(origin, direction, max_angle_deg):
	var look_basis = Basis.looking_at(direction)
	var max_angle = deg_to_rad(max_angle_deg)
	var radius = _gaussian_spread(randf(), max_angle, DISTRIBUTION_FLATNESS)
	if abs(radius) > max_angle:
		radius = max_angle * sign(radius)
	var angle = TAU * randf()
	
	var offset = Vector3(
		cos(angle) * radius,
		sin(angle) * radius,
		0.0
	)
	return (look_basis * offset) + direction

func raycast_spread(
	origin: Vector3, 
	direction: Vector3, 
	max_angle_deg: float, 
	mask: int = TraceMask.SOLID) -> TraceHit:
	
	var spread_dir = get_random_vector_in_cone(origin, direction, max_angle_deg)
	return raycast(origin, spread_dir, mask)
	
func _gaussian_spread(u, spread, flatness):
	return pow(-2.0 * log(u), 1.0 - flatness) * spread * flatness


func linecast(
	origin: Vector3, 
	end: Vector3, 
	mask: int = TraceMask.SOLID) -> TraceHit:

	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(origin, end, mask)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result = space.intersect_ray(query)
	if not result:
		if ENABLE_HITSCAN_DEBUG:
			DebugDraw3D.draw_line(origin, end, Color.SKY_BLUE, HITSCAN_DISPLAY_TIME)
		return TraceHit.create_empty(origin, (end - origin).normalized())
		
	var result_collider = result["collider"]
	var result_normal = result["normal"]
	var result_pos = result["position"]
	var result_dist = result_pos.distance_to(origin)
	var trace_result = TraceHit.new(origin, result_pos, result_normal, result_collider, result_dist)
	
	if ENABLE_HITSCAN_DEBUG:
		DebugDraw3D.draw_line(origin, result_pos, Color.GREEN, HITSCAN_DISPLAY_TIME)
		DebugDraw3D.draw_line(result_pos, end, Color.RED, HITSCAN_DISPLAY_TIME)
	
	return trace_result


var cached_capsule_rid = null

const SPHERECAST_STEPS = 16

## Note, the returned list is sorted from closest to farthest.[br]
## The trace from the exploratory linecast is guaranteed to be at the end of the list.
func spherecast(
	origin: Vector3, 
	dir: Vector3, 
	radius: float, 
	mask = TraceMask.SOLID, 
	max_dist = 160.0) -> Array[TraceHit]:
	
	var initial_trace_end = origin + (dir * max_dist)
	
	var initial_trace: TraceHit = TraceQuery.linecast(
		origin,
		initial_trace_end,
		mask
	)
	
	var trace_end = initial_trace_end
	
	if not initial_trace.is_empty():
		trace_end = initial_trace.hit_pos
	
	if not cached_capsule_rid:
		cached_capsule_rid = PhysicsServer3D.capsule_shape_create()
	
	var mid_point = (origin + trace_end) / 2.0
	var capsule_height = origin.distance_to(trace_end)
	
	var capsule_data = {}
	capsule_data["radius"] = radius
	capsule_data["height"] = capsule_height
	
	PhysicsServer3D.shape_set_data(cached_capsule_rid, capsule_data)
	
	var capsule_basis = Basis()
	capsule_basis.y = (trace_end - origin).normalized()
	
	var up = Vector3.UP
	if abs(capsule_basis.y.dot(up)) > 0.99:
		up = Vector3.RIGHT
	
	capsule_basis.x = up.cross(capsule_basis.y).normalized()
	capsule_basis.z = capsule_basis.y.cross(capsule_basis.x).normalized()
	
	var capsule_transform = Transform3D(capsule_basis, mid_point)
	
	var query_params = PhysicsShapeQueryParameters3D.new()
	query_params.shape_rid = cached_capsule_rid
	query_params.transform = capsule_transform
	query_params.collision_mask = mask
	query_params.collide_with_bodies = true
	query_params.collide_with_areas = true
	
	var raw_results = get_world_3d().direct_space_state.intersect_shape(query_params)
	
	var hit_colliders = {}
	var result: Array[TraceHit] = []
	
	for hit in raw_results:
		if not hit:
			continue
		var collider: CollisionObject3D = hit["collider"]
		
		if hit_colliders.has(collider.get_rid()):
			continue
		
		var trace_hit = TraceHit.new(
			origin,
			collider.global_position,
			Vector3.FORWARD,
			collider,
			(collider.global_position - origin).length()
		)
		hit_colliders[collider.get_rid()] = true
		result.append(trace_hit)
	
	result.sort_custom(func (a, b): return a.hit_distance < b.hit_distance)
	result.append(initial_trace)
	return result


func overlap_sphere(pos: Vector3, radius: float, collision_mask: int) -> Array[TraceHit]:
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return []
	
	# Create sphere shape
	sphere_shape.radius = radius
	
	# Setup query
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere_shape
	query.transform = Transform3D.IDENTITY.translated(pos)
	query.collision_mask = collision_mask
	query.collide_with_bodies = true
	query.collide_with_areas = true
	
	# Perform query
	var results = space_state.intersect_shape(query, 9999)
	
	# Extract and return colliders
	var trace_hits: Array[TraceHit] = []
	var hit_colliders = {}
	for result in results:
		var collider = result.get("collider") as CollisionObject3D
		if collider and not collider in hit_colliders:
			hit_colliders[collider] = null
			var dir_to_candidate = (collider.global_position - pos)
			var hit = TraceHit.new(pos, 
						collider.global_position, 
						dir_to_candidate.normalized(), 
						collider, 
						dir_to_candidate.length()
			)
			#print(collider.get_parent().name + ":" + collider.name)

			#DebugDraw3D.draw_sphere(collider.global_position, 0.0625, Color.BLUE, 2.5)
			trace_hits.append(hit)
	
	return trace_hits
