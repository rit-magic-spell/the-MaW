extends Control

@export_group("Player Components")
@export var Controls : PlayerInputComponent
@export var View : EntityViewComponent
@export var Body : EntityBodyComponent
@export var Weapons: EntityInventoryComponent

@export_group("Component Info Labels")
@export var GameInfo : Label
@export var ControlsInfo : Label
@export var WeaponInfo : Label
@export var BodyInfo : Label

func _process(_delta):
	_write_game_ui()
	_write_input_ui()
	_write_view_ui()
	_write_body_ui()

func _write_game_ui():
	var format = "Rendering FPS: %s\nPhysics Tick Rate: %s\nPhysics Frame Time: %s"
	var out_str = format % [Engine.get_frames_per_second(), Engine.physics_ticks_per_second, get_physics_process_delta_time()]
	GameInfo.text = out_str
	pass
	
func _write_input_ui():
	var format = "Movement Input: %s\nWish Direction: %s\nWish Speed: %s m/s (%s u/s)\nJump Pressed: %s\nDuck Pressed: %s\n"
	var extra = "Jump On: %s\nHas Jump Queued Midair: %s\nHas Jumped At All: %s\n"

	var out_str = format % \
	[ 	Controls.movement_input, 
		Controls.move_dir.normalized(), 
		round(Controls.move_dir.length()), 
		round(Controls.move_dir.length() * 39.37), 
		Controls.jump_on, 
		Controls.duck_on
	]
	out_str += extra % \
	[
		Controls.jump_on,
		Controls.has_midair_queued,
		Controls.has_jumped,
	]
	ControlsInfo.text = out_str
	pass
	
func _write_view_ui():
	var health_str = "Current Health: %s" % [snapped(Body.Root.entity_health.current_health, 0)]
	if Body.Root.entity_health.current_overheal > 0.0:
		health_str += " + " + str(snapped(Body.Root.entity_health.current_overheal, 0.01))
	health_str += "\n"
	var format = health_str + "Current Ammo: %s / %s\nAmmo Remaining: %s / %s\nPersistent Counter: %s / %s"
	
	#format += "\nM1: [%s-%s] | M2: [%s-%s] | R: [%s-%s]"
	format += "\nCurrent State: %s"
	var current_weapon = Weapons.entity_loadout_component.get_current_weapon()
	var out_str = "lol"
	
	if current_weapon == null or not current_weapon.is_weapon_valid(): 
		var lmao = []
		for i in range(format.count("%s")):
			lmao.append("N/A")
		out_str = format % lmao
	else:
		var data = current_weapon.get_weapon_data()
		out_str = format % [
			data.current_ammo, 
			data.max_ammo,
			current_weapon.AmmoData.get_ammo_amount(data.ammo_type),
			current_weapon.AmmoData.max_ammo[data.ammo_type],
			data.persistent_counter,
			data.persistent_counter_max,
			#Weapons.current_weapon.is_firing,
			#Weapons.current_weapon.just_started_firing,
			#Weapons.current_weapon.is_alt_firing,
			#Weapons.current_weapon.just_started_alt_firing,
			#Weapons.current_weapon.is_reloading,
			#Weapons.current_weapon.just_started_reloading,
			current_weapon.get_state_machine().name
		]
	WeaponInfo.text = out_str

	
func _write_body_ui():
	var format = "Position: %s\nVelocity: %s\nSpeed: %s m/s (%s u/s)\nDucking: %s\nDucked: %s"
	var h_vel = Vector2(Body.velocity.x, Body.velocity.z)
	var out_str = format % [Body.global_position, Body.velocity, snapped(h_vel.length(), 0.01), round(h_vel.length() * 39.37), Body.ducking, Body.ducked]
	BodyInfo.text = out_str
	pass

	
