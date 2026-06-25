extends Control

class_name CrosshairManager

const CROSSHAIR_EMPTY = preload("res://player/inventory/weapons/crosshairs/crosshair_empty.png")
const CROSSHAIR_SHOTGUN = preload("res://player/inventory/weapons/crosshairs/crosshair_shotgun.png")
const CROSSHAIR_THOMPSON = preload("res://player/inventory/weapons/crosshairs/crosshair_thompson.png")
const CROSSHAIR_REVOLVER = preload("res://player/inventory/weapons/crosshairs/crosshair_revolver.png")
@onready var texture_rect: TextureRect = $TextureRect
@export var player_hud: PlayerHUD

var crosshair_scale := 1.0
var default_crosshair_scale = 1.0



enum CROSSHAIR
{
	EMPTY,
	SHOTGUN,
	REVOLVER,
	THOMPSON
}

const crosshairs = [
	CROSSHAIR_EMPTY,
	CROSSHAIR_SHOTGUN,
	CROSSHAIR_REVOLVER,
	CROSSHAIR_THOMPSON
]

#func _ready():
	#add_to_group(Effigy.RESET_GROUP)

func _process(delta):
	crosshair_scale = Util.exp_decay(crosshair_scale, 
	default_crosshair_scale, 
	10,
	delta)
	texture_rect.scale = Vector2.ONE * crosshair_scale

## Bumps the crosshair scale temporarily
## Decays over time.
func bump_crosshair_scale(new_scale):
	crosshair_scale = new_scale

func update_crosshair(new_crosshair: CROSSHAIR):
	if len(crosshairs) <= 0:
		return
	var new = crosshairs[new_crosshair]
	texture_rect.texture = new


func handle_reset():
	var player = player_hud.player
	var weapon: Weapon = player.entity_inventory.entity_loadout_component.get_current_weapon()
	
	if weapon and weapon.is_weapon_valid():
		update_crosshair(weapon.get_weapon_data().crosshair)
	else:
		update_crosshair(CROSSHAIR.EMPTY)
