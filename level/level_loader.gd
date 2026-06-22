extends Area3D

class_name LevelLoader


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	monitoring = true
	collision_mask = TraceMask.PLAYER
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node3D):
	if body is EntityBodyComponent:
		GameManager.load_next_level()
