extends Button

@onready var script_runner_panel: Control = $"../../../ScriptRunnerBackground"

func _on_pressed():
	script_runner_panel.visible = true
	script_runner_panel.move_to_front()
