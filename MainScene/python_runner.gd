## Shows the Script Runner panel when the Python Runner button is pressed,
## bringing it to the front so it overlays other UI elements.

extends Button

@onready var script_runner_panel: Control = $"../../../ScriptRunnerBackground"


func _on_pressed() -> void:
	script_runner_panel.visible = true
	script_runner_panel.move_to_front()
