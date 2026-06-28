extends Control

class_name PlayerHUD

@onready var player: Player = $".."

@onready var entity_inventory_component: EntityInventoryComponent = $"../Entity Inventory Component"
@onready var entity_health_component: EntityHealthComponent = $"../EntityHealthComponent"
@onready var pain_flash_rect: ColorRect = $PainFlashRect

@onready var current_ammo_label: RichTextLabel = $CurrentAmmoLabel
@onready var current_health_label: RichTextLabel = $CurrentHealthLabel
@onready var timestop_progress: TextureProgressBar = $TextureProgressBar

@onready var crosshair_manager: CrosshairManager = $CrosshairManager
@onready var game_text_manager: GameTextManager = $GameTextLabel

@onready var health_bar: ProgressBar = $HealthBar

@onready var primary_weapon_icon: ColorRect = $PrimaryWeaponIcon
@onready var secondary_weapon_icon: ColorRect = $SecondaryWeaponIcon

## Default primary weapon icon
var _pw_icon_default:ColorRect
## Default secondary weapon icon
var _sw_icon_default:ColorRect
## Tween weapon swap
var _weapon_swap_tween:Tween
## Value to interpolate [member health_bar.value] toward.
var _target_health_value:float


func _ready():
	entity_health_component.on_taken_damage.connect(update_rect)
	entity_inventory_component.entity_loadout_component.swapped_away.connect(_on_weapon_swapped_away)
	
	_pw_icon_default = primary_weapon_icon.duplicate()
	_sw_icon_default = secondary_weapon_icon.duplicate()
	

func _process(delta: float) -> void:
	# Interpolate health bar value
	health_bar.value = move_toward(health_bar.value, _target_health_value, delta * 2.0)
	

# TODO - This is TEMPORARY
# I swear to god if this makes it to production I will scream
func _physics_process(delta: float) -> void:
	# health
	var health = entity_health_component
	current_health_label.text = str(snapped(health.current_health + health.current_overheal, 1))
	
	# Set target healthbar value (current health percent)
	_target_health_value = entity_health_component.current_health / entity_health_component.get_max_health()
	
	var rect_alpha = pain_flash_rect.color.a
	rect_alpha -= delta
	rect_alpha = max(0.0, rect_alpha)
	pain_flash_rect.color.a = rect_alpha
	
	var current_weapon = entity_inventory_component.entity_loadout_component.get_current_weapon()
	if not current_weapon:
		current_ammo_label.text = ""
	else:
		# ammo
		var data = current_weapon.get_weapon_data()
		if not data:
			return
		var cur_ammo = data.current_ammo
		var inv = entity_inventory_component
		var ammo_inv = inv.entity_ammo_data
		var cur_stored = ammo_inv.get_ammo_amount(current_weapon.get_weapon_data().ammo_type)
		current_ammo_label.text = "%s : %s" % [cur_ammo, cur_stored]


func update_rect(damage_info: DamageInfo):
	pain_flash_rect.color.a += 0.2
	if pain_flash_rect.color.a > 0.5:
		pain_flash_rect.color.a = 0.5


## Updates weapon icons based on current active weapon
func _update_weapon_icons(weapon:Weapon) -> void:
	var slot_idx:int = entity_inventory_component.entity_loadout_component.slot_idx
	
	# Swap icon color
	primary_weapon_icon.color = _pw_icon_default.color if slot_idx == 0 else _sw_icon_default.color
	secondary_weapon_icon.color = _sw_icon_default.color if slot_idx == 0 else _pw_icon_default.color
	
	# Create tween
	if _weapon_swap_tween:
		_weapon_swap_tween.kill()
	_weapon_swap_tween = create_tween().set_parallel()
	
	# Swap icon sizes
	var pw_scale:Vector2 = _pw_icon_default.scale if slot_idx == 0 else _sw_icon_default.scale
	var sw_scale:Vector2 = _sw_icon_default.scale if slot_idx == 0 else _pw_icon_default.scale
	var weapon_swap_time:float = entity_inventory_component.entity_loadout_component.swap_away_timer.wait_time
	var half_swap_time := weapon_swap_time / 2.0
	
	_weapon_swap_tween.tween_property(primary_weapon_icon, "scale", pw_scale, half_swap_time).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	_weapon_swap_tween.tween_property(secondary_weapon_icon, "scale", sw_scale, half_swap_time).\
	set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Ammo label hop anim
	_weapon_swap_tween.tween_property(current_ammo_label, "scale", Vector2.ONE * 1.15, half_swap_time).\
	set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_weapon_swap_tween.set_parallel(false).tween_property(current_ammo_label, "scale", Vector2.ONE, half_swap_time).\
	set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_weapon_swapped_away(weapon:Weapon) -> void:
	# Weapons switched
	_update_weapon_icons(weapon)
