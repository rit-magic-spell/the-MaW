extends Camera3D

@export var main_camera: Camera3D
@onready var gun_viewport: SubViewport = $".."

func _ready():
	environment = main_camera.environment
	

func _process(_delta):
	global_transform = main_camera.global_transform
	gun_viewport.size = get_window().size
