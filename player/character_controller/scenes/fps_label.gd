extends RichTextLabel

@export var show_exact: bool = false

var frame_times: Array[float] = []
var elapsed: float = 0.0
const UPDATE_INTERVAL: float = 0.25

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_fps_counter"):
		visible = not visible

func _process(delta: float) -> void:
	frame_times.append(delta)
	elapsed += delta
	
	if elapsed < UPDATE_INTERVAL:
		return
	
	var total: float = 0.0
	for t in frame_times:
		total += t
	
	var avg_frame_time = total / frame_times.size()
	var avg_fps = 1.0 / avg_frame_time

	text = "%d" % floori(avg_fps)
	
	frame_times.clear()
	elapsed = 0.0
