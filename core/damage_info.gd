extends Resource

class_name DamageInfo

enum DAMAGE_TYPE
{
	GENERIC,
	MAGIC,
	BURN,
	ELECTRIC
}


@export_range(0.0, 9999.0) var damage: float = 0.0
@export_range(0.0, 999.0) var pressure_damage: float = 0.0
@export_range(0.0, 999.0) var posture_damage: float = 0.0
@export var damage_type: DAMAGE_TYPE = DAMAGE_TYPE.GENERIC

var source: Node3D
@export var source_position: Vector3 = Vector3.ZERO


func get_source():
	return source
	
func set_source(dmg_source: Node):
	source = dmg_source

func dmg_copy() -> DamageInfo:
	var new_info = self.duplicate()
	new_info.set_source(get_source())
	return new_info


func _to_string() -> String:
	var str_damage_type = str(DAMAGE_TYPE.keys()[damage_type])
	var str_pressure = str(pressure_damage)
	var str_posture = str(posture_damage)
	var str_damage = str(damage)
	var str_source = str(source.name) if source else "NULL"
	var result = "Damage [%s] : Type [%s] : Pressure DMG [%s] : Posture DMG [%s] : Source [%s]" % \
				[str_damage, str_damage_type, str_pressure, str_posture, str_source]
	return result
