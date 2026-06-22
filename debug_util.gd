extends Node


func draw_resource_values(resource: Resource, position: Vector3):
	var fields = Util.get_trimmed_property_list(resource)
	var text = ""
	for fieldname in fields:
		var value = resource.get(fieldname)
		if value is float:
			value = snapped(value, 0.01)
		text += "%s: [%s]\n" % [fieldname, value]
	DebugDraw3D.draw_text(position, text)
