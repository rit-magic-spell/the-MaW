extends Area3D

@export var refire_time: float
@export var damage: float = 5.0
@export var damage_type: DamageInfo.DAMAGE_TYPE = DamageInfo.DAMAGE_TYPE.GENERIC


var id: String

var player: Player
var damage_info: DamageInfo


var timer: float = 0.0
func _ready():
	if Engine.is_editor_hint():
		return
	
	body_entered.connect(on_body_enter)
	body_exited.connect(on_body_exit)
	id = Util.get_entity_id(self)
	damage_info = DamageInfo.new()
	damage_info.damage = damage
	damage_info.damage_type = damage_type

func _physics_process(delta: float) -> void:
	
	if not player:
		timer = 0.0
		return

	timer += delta
	if timer > refire_time:
		player.entity_health.take_damage(damage_info)
		timer = 0.0
	

func on_body_enter(body):
	if body is not EntityBodyComponent:
		return
	player = body.Root
	timer = refire_time * 2.0

func on_body_exit(body):
	if body is not EntityBodyComponent:
		return
	player = null
