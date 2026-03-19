## Manages the Settings panel lifecycle:
##   - Pressing the button shows the Settings panel and locks camera movement.
##   - Receiving the "menu_closed" signal hides the panel and restores camera movement.

extends Button

@onready var settings_background: Control = get_node("/root/MainScene/ControlLayer/SettingsBackground")


func _on_pressed() -> void:
	settings_background.show()
	CameraSignals.disable_camera_movement.emit()
	CameraSignals.disable_camera_zoom.emit()


func _on_settings_settings_menu_closed() -> void:
	settings_background.hide()
	CameraSignals.enable_camera_movement.emit()
	CameraSignals.enable_camera_zoom.emit()
