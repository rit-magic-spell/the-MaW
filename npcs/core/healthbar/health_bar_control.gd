extends Control

@export var tracked_npc: NPCBase

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var pressure_bar_a: TextureProgressBar = $PressureBar
@onready var pressure_bar_b: TextureProgressBar = $PressureBar2



func set_npc(npc: NPCBase):
	tracked_npc = npc
	health_bar.max_value = tracked_npc.entity_health.get_max_health()
	health_bar.value = tracked_npc.entity_health.current_health
	pressure_bar_a.max_value = tracked_npc.npc_data.stagger_threshold
	pressure_bar_b.max_value = tracked_npc.npc_data.stagger_threshold

func _process(delta):
	if not tracked_npc:
		return
	
	var health = tracked_npc.entity_health
	if health.is_entity_dead():
		health_bar.value = 0.0
	else:
		health_bar.value = Util.exp_decay(health_bar.value, health.current_health, 8.0, delta)
	
	
	var pressure = tracked_npc.npc_data.current_pressure_value
	
	pressure_bar_a.value = Util.exp_decay(pressure_bar_a.value, pressure, 8.0, delta)
	if pressure_bar_a.value <= 0.05:
		pressure_bar_a.value = 0.0	
	pressure_bar_b.value = pressure_bar_a.value
	
