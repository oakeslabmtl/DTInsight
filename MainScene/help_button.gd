## help_button.gd
## Opens the help popup when the Help button is pressed.

extends Button


func _on_help_button_pressed() -> void:
	$HelpPopup.popup()
