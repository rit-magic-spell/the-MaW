extends Sprite3D

const LIVE_TIME = 0.05
const SHOT_ENERGY = 0.5

var timer = 0.0

var player: Player

var base_scale = Vector3.ONE
var random_rot: float = 0.0

@onready var shot_light: OmniLight3D = $OmniLight3D

func _ready():
	player = GameManager.player
	base_scale = scale
	shot_light.light_energy = 0.0

var was_visible = false
func _process(delta):
	if visible:
		if not was_visible:
			shot_light.light_energy = SHOT_ENERGY
			shot_light.global_position = global_position
			player.player_camera.night_light.light_color = shot_light.light_color
		look_at(player.player_camera.global_position)
		if timer == 0.0:
			random_rot = randf() * PI
		rotation.z = random_rot
		var scale_mult = inverse_lerp(0.05, 0.0, timer)
		scale = base_scale * scale_mult
		timer += delta
	
	
	shot_light.light_energy = Util.exp_decay(shot_light.light_energy, 0.0, 1.0, delta)
	
	if timer > LIVE_TIME:
		timer = 0.0
		visible = false
		scale = base_scale
	was_visible = visible
