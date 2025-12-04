extends Button

# Path of the script
var script_path = "script_test.py" 

# Execute a Python script when the button is pressed
func _on_pressed():
	if not FileAccess.file_exists(script_path):
		printerr("Error : Python file not found at : ", script_path)
		return
	var command = "python" 
	var args = [script_path]
	var output = []	
	var exit_code = OS.execute(command, args, output, true)	
	if exit_code == 0:
		print("Script successfully executed", output)
	else:
		printerr("Python error (Code %s) : " % exit_code, output)
