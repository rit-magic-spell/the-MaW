extends Sprite3D


func _ready():
	frame = randi() % (hframes * vframes)

func _on_timer_timeout() -> void:
	queue_free()

func handle_reset():
	queue_free()
