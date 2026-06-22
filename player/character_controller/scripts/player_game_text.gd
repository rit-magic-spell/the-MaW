extends RichTextLabel


class_name GameTextManager

var display_text_timers = {}

var display_text_ordered = []

func _physics_process(delta: float) -> void:
	var final = ""
	for display_text in display_text_ordered:
		final += "%s\n" % display_text
		display_text_timers[display_text] -= delta
		if display_text_timers[display_text] <= 0.0:
			display_text_timers.erase(display_text)
			display_text_ordered.remove_at(display_text_ordered.find(display_text))
	
	text = final


func submit_text(hud_text, duration = 1.0):
	if display_text_timers.has(hud_text):
		display_text_ordered.remove_at(display_text_ordered.find(hud_text))
	
	display_text_ordered.push_front(hud_text)
	display_text_timers[hud_text] = duration
