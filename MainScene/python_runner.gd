## Shows the Script Runner panel when the Python Runner button is pressed,
## bringing it to the front so it overlays other UI elements.

extends Button

func _on_pressed() -> void:
	$ScriptRunnerPopup.show()
	$ScriptRunnerPopup.grab_focus()
