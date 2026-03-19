extends Control

# Get references to nodes for modification
@onready var path_line_edit = $VBoxContainer/InputContainer/PathLineEdit
@onready var file_dialog = $FileDialog

# Called when the user clicks "Pick File"
func _on_pick_button_pressed():
	# Opens the file selection popup
	file_dialog.popup_centered()

# Called when the user has chosen a file in the FileDialog
func _on_file_dialog_file_selected(path):
	# Display the path in the text field
	path_line_edit.text = path

# Called when the user clicks "Run"
func _on_run_button_pressed():
	var script_path = path_line_edit.text
	
	if script_path == "":
		printerr("Error: No file selected.")
		return

	if not FileAccess.file_exists(script_path):
		printerr("Error: Python file not found at: ", script_path)
		return

	# Python execution code setup
	var command = "python"
	if not OS.has_feature("windows"):
		command = "python3"
		
	var args = [script_path]
	var output = []
	print("Launching script: ", script_path)
	
	# Execution (blocking with true; consider deferring if the script is long)
	var exit_code = OS.execute(command, args, output, true)
	
	if exit_code == 0:
		print("Script executed successfully: ", output)
		# Hide the popup on success
		_on_back_button_pressed()
	else:
		printerr("Python Error (Code %s): " % exit_code, output)

# Called when the user clicks "Back"
func _on_back_button_pressed():
	# Simply hide this panel
	get_parent().visible = false
