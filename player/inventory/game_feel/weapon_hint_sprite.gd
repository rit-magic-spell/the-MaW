extends Sprite3D

## TODO - This is temporary for the incubator


func _process(delta):
	var alpha = modulate.a
	alpha = Util.exp_decay(alpha, 0.0, 20.0, delta)
	modulate.a = alpha

func sparkle():
	modulate.a = 1.0
