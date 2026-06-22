extends Sprite3D

const LIFETIME = 0.25
var current_lifetime = 0.0

func setup_hitmarker():
	current_lifetime = 0.0
	modulate.a = 1.0

func is_active():
	return current_lifetime <= LIFETIME

func _process(delta: float) -> void:
	if current_lifetime > LIFETIME:
		modulate.a = 0.0
		return
		
	var alpha_lerp = inverse_lerp(0.0, LIFETIME, current_lifetime)
	var alpha = lerp(1.0, 0.0, alpha_lerp)
	
	current_lifetime += delta
	
	modulate.a = alpha
	
