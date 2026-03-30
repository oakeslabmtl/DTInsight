extends Window

@export var string_parameters: Array[String] = [
	"--mode", "--input-path", "--output-dir", "--chunk-size",
	"--chunk-overlap", "--temperature", "--model-name",
	"--judge-model-name", "--embedding-model", "--exp-id",
	"--max-judge-retries", "--max-oml-retries", "--baseline-max-chars"
]
@export var boolean_parameters: Array[String] = [
	"--no-save", "--baseline-full-doc"
]

# Node references
@onready var project_dir_line_edit = $VBoxContainer/ProjectDirContainer/ProjectDirLineEdit
@onready var script_line_edit = $VBoxContainer/ScriptContainer/ScriptLineEdit
@onready var project_dir_dialog = $ProjectDirDialog
@onready var dynamic_params_container = $VBoxContainer/ParamsScrollContainer/DynamicParamsContainer
@onready var run_button = $VBoxContainer/ActionButtons/RunButton
@onready var status_label = $VBoxContainer/StatusLabel

var _run_thread: Thread

func _ready():
	_build_dynamic_ui()
	close_requested.connect(_on_back_button_pressed)
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed():
	if visible:
		CameraSignals.disable_camera_movement.emit()
		CameraSignals.disable_camera_zoom.emit()
	else:
		CameraSignals.enable_camera_movement.emit()
		CameraSignals.enable_camera_zoom.emit()

func _build_dynamic_ui():
	# Build String inputs
	for param in string_parameters:
		var hbox = HBoxContainer.new()
		var label = Label.new()
		label.text = param
		label.custom_minimum_size = Vector2(160, 0)

		var line_edit = LineEdit.new()
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line_edit.set_meta("param_flag", param)

		hbox.add_child(label)
		hbox.add_child(line_edit)
		dynamic_params_container.add_child(hbox)

	# Build Boolean inputs
	for param in boolean_parameters:
		var checkbox = CheckBox.new()
		checkbox.text = param
		checkbox.set_meta("param_flag", param)
		dynamic_params_container.add_child(checkbox)

# Called when the user clicks "Pick folder"
func _on_project_dir_pick_button_pressed():
	project_dir_dialog.popup_centered()

# Called when the user has chosen a project directory
func _on_project_dir_dialog_dir_selected(dir: String):
	project_dir_line_edit.text = dir

# Called when the user clicks "Run"
func _on_run_button_pressed():
	if _run_thread != null and _run_thread.is_alive():
		return # Already running

	var project_dir = project_dir_line_edit.text.strip_edges()
	var script_name = script_line_edit.text.strip_edges()

	if project_dir == "":
		printerr("Error: No project folder selected.")
		return

	if script_name == "":
		printerr("Error: No script name specified.")
		return

	# Build arguments: uv run <script> <params...>
	var args: PackedStringArray = PackedStringArray()
	args.append("run")
	args.append(script_name)

	for child in dynamic_params_container.get_children():
		if child is HBoxContainer:
			var line_edit = child.get_child(1) as LineEdit
			var val = line_edit.text.strip_edges()
			if val != "":
				args.append(line_edit.get_meta("param_flag"))
				args.append(val)
		elif child is CheckBox:
			if child.button_pressed:
				args.append(child.get_meta("param_flag"))

	print("Running from: ", project_dir)
	print("Command: uv ", " ".join(args))

	run_button.disabled = true
	status_label.text = "Status: Running python script in background..."

	_run_thread = Thread.new()
	_run_thread.start(_execute_script.bind(project_dir, args))

func _execute_script(project_dir: String, args: PackedStringArray):
	var output = []
	# Build a shell command that cd's into the project dir first, then runs uv
	var shell_command: String
	var shell_args: PackedStringArray

	if OS.has_feature("windows"):
		shell_command = "cmd.exe"
		shell_args = PackedStringArray(["/c", "cd /d " + project_dir + " && uv " + " ".join(args)])
	else:
		shell_command = "/bin/sh"
		shell_args = PackedStringArray(["-c", "cd " + project_dir.c_escape() + " && uv " + " ".join(args)])

	var exit_code = OS.execute(shell_command, shell_args, output, true)

	# After finished, call deferred to update UI safely
	call_deferred("_on_script_finished", exit_code, output)

func _on_script_finished(exit_code: int, output: Array):
	# Wait for thread safety
	_run_thread.wait_to_finish()
	run_button.disabled = false

	if exit_code == 0:
		print("Script executed successfully:\n", str(output))
		status_label.text = "Status: Success!"
		# Trigger the Fuseki query so the visualisation reflects latest data.
		var fuseki_button = get_tree().root.get_node("MainScene/%FusekiCallerButton")
		fuseki_button._on_pressed()
	else:
		printerr("Python Error (Code %s):\n" % exit_code, str(output))
		status_label.text = "Status: Error (Code %s)" % exit_code

# Called when the user clicks "Back" or the window X button
func _on_back_button_pressed():
	hide()
