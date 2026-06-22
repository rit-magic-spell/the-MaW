extends Node

var gameplay_scale: float = 1.0

var gameplay_tween: Tween
var global_tween: Tween

func set_gameplay_timescale(new_timescale: float):
	gameplay_scale = max(0.0, new_timescale)

func get_gameplay_timescale():
	return gameplay_scale

func slow_gameplay_time(target_speed: float, recover_time: float):
	if gameplay_tween and gameplay_tween.is_running():
		gameplay_tween.kill()
	gameplay_tween = create_tween()
	gameplay_tween.set_ease(Tween.EASE_OUT)
	gameplay_tween.set_trans(Tween.TRANS_LINEAR)
	gameplay_tween.tween_property(self, "gameplay_scale", target_speed, 0.1)
	gameplay_tween.tween_interval(0.1)
	gameplay_tween.set_trans(Tween.TRANS_QUAD)
	gameplay_tween.tween_property(self, "gameplay_scale", 1.0, recover_time)

func slow_global_time(target_speed: float, recover_time: float):
	if global_tween and global_tween.is_running():
		global_tween.kill()
	global_tween = create_tween()
	global_tween.set_ease(Tween.EASE_OUT)
	global_tween.set_trans(Tween.TRANS_LINEAR)
	global_tween.tween_property(Engine, "time_scale", target_speed, 0.1)
	global_tween.tween_interval(0.1)
	global_tween.set_trans(Tween.TRANS_QUAD)
	global_tween.tween_property(Engine, "time_scale", 1.0, recover_time)
