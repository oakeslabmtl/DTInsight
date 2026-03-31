extends Window

# Basic parameters shown by default
@export var basic_string_parameters: Array[String] = [
	"--input-path", "--model-name"
]

# Advanced parameters hidden behind a toggle
@export var advanced_string_parameters: Array[String] = [
	"--mode", "--output-dir", "--chunk-size", "--chunk-overlap", "--temperature",
	"--embedding-model", "--exp-id", "--judge-model-name",
	"--max-judge-retries", "--max-oml-retries", "--baseline-max-chars"
]
@export var advanced_boolean_parameters: Array[String] = [
	"--no-save", "--baseline-full-doc"
]

var default_values: Dictionary = {
	"--mode": "both",
	"--input-path": "",
	"--output-dir": "experiments",
	"--chunk-size": "3000",
	"--chunk-overlap": "500",
	"--temperature": "0.1",
	"--model-name": "glm-4.7:cloud",
	"--judge-model-name": "deepseek-v3.2:cloud",
	"--embedding-model": "embeddinggemma",
	"--exp-id": "",
	"--max-judge-retries": "0",
	"--max-oml-retries": "3",
	"--baseline-max-chars": "24000",
	"--no-save": true,
	"--baseline-full-doc": true
}

# Node references
@onready var project_dir_line_edit = $VBoxContainer/ProjectDirContainer/ProjectDirLineEdit
@onready var script_line_edit = $VBoxContainer/ScriptContainer/ScriptLineEdit
@onready var project_dir_dialog = $ProjectDirDialog
@onready var dynamic_params_container = $VBoxContainer/ParamsScrollContainer/DynamicParamsContainer
@onready var run_button = $VBoxContainer/ActionButtons/RunButton
@onready var status_label = $VBoxContainer/StatusLabel

var _input_path_line_edit: LineEdit
var _input_path_dialog: FileDialog
var _advanced_container: VBoxContainer

var _run_thread: Thread

func _ready():
	script_line_edit.text = "src\\main.py"
	_build_input_path_dialog()
	_build_dynamic_ui()
	close_requested.connect(_on_back_button_pressed)
	visibility_changed.connect(_on_visibility_changed)

func _build_input_path_dialog():
	_input_path_dialog = FileDialog.new()
	_input_path_dialog.title = "Select Input File"
	_input_path_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_input_path_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_input_path_dialog.filters = PackedStringArray(["*.pdf ; PDF Files", "*.*"])
	_input_path_dialog.size = Vector2i(935, 550)
	_input_path_dialog.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_MAIN_WINDOW_SCREEN
	_input_path_dialog.file_selected.connect(_on_input_path_dialog_file_selected)
	add_child(_input_path_dialog)

func _on_visibility_changed():
	if visible:
		CameraSignals.disable_camera_movement.emit()
		CameraSignals.disable_camera_zoom.emit()
	else:
		CameraSignals.enable_camera_movement.emit()
		CameraSignals.enable_camera_zoom.emit()

func _build_dynamic_ui():
	# Build basic string inputs (always visible)
	for param in basic_string_parameters:
		dynamic_params_container.add_child(_create_string_param_row(param))

	# Advanced toggle button
	var toggle_btn = CheckButton.new()
	toggle_btn.text = "Advanced Options"
	toggle_btn.toggled.connect(_on_advanced_toggled)
	dynamic_params_container.add_child(toggle_btn)

	# Advanced container (hidden by default)
	_advanced_container = VBoxContainer.new()
	_advanced_container.visible = false
	_advanced_container.add_theme_constant_override("separation", 5)
	dynamic_params_container.add_child(_advanced_container)

	for param in advanced_string_parameters:
		_advanced_container.add_child(_create_string_param_row(param))
	
	for param in advanced_boolean_parameters:
		var checkbox = CheckBox.new()
		checkbox.text = param
		checkbox.set_meta("param_flag", param)
		if default_values.has(param):
			checkbox.button_pressed = default_values[param]
		_advanced_container.add_child(checkbox)

func _create_string_param_row(param: String) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	var label = Label.new()
	label.text = param
	label.custom_minimum_size = Vector2(160, 0)

	var line_edit = LineEdit.new()
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.set_meta("param_flag", param)
	if default_values.has(param):
		line_edit.text = default_values[param]
		line_edit.placeholder_text = default_values[param]

	hbox.add_child(label)
	hbox.add_child(line_edit)

	# Add a file picker button for --input-path
	if param == "--input-path":
		_input_path_line_edit = line_edit
		var pick_btn = Button.new()
		pick_btn.text = "Pick file"
		pick_btn.pressed.connect(_on_input_path_pick_button_pressed)
		hbox.add_child(pick_btn)

	return hbox

func _on_advanced_toggled(toggled_on: bool):
	_advanced_container.visible = toggled_on

# Called when the user clicks "Pick folder"
func _on_project_dir_pick_button_pressed():
	project_dir_dialog.popup_centered()

# Called when the user has chosen a project directory
func _on_project_dir_dialog_dir_selected(dir: String):
	project_dir_line_edit.text = dir

func _on_input_path_pick_button_pressed():
	_input_path_dialog.popup_centered()

func _on_input_path_dialog_file_selected(path: String):
	# Make the path relative to the project directory if possible
	var project_dir = project_dir_line_edit.text.strip_edges()
	if project_dir != "" and path.begins_with(project_dir):
		path = path.substr(project_dir.length()).lstrip("/").lstrip("\\")
	_input_path_line_edit.text = path

func _collect_params_from(container: Control, args: PackedStringArray):
	for child in container.get_children():
		if child is HBoxContainer:
			var line_edit = child.get_child(1) as LineEdit
			var val = line_edit.text.strip_edges()
			if val != "":
				args.append(line_edit.get_meta("param_flag"))
				args.append(val)
		elif child is CheckBox:
			if child.button_pressed:
				args.append(child.get_meta("param_flag"))

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

	_collect_params_from(dynamic_params_container, args)
	if _advanced_container:
		_collect_params_from(_advanced_container, args)

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

	# Quote each argument so paths with spaces are handled correctly
	var quoted_args: PackedStringArray = PackedStringArray()
	for arg in args:
		quoted_args.append("\"" + arg + "\"")

	if OS.has_feature("windows"):
		shell_command = "cmd.exe"
		shell_args = PackedStringArray(["/c", "cd /d \"" + project_dir + "\" && uv " + " ".join(quoted_args)])
	else:
		shell_command = "/bin/sh"
		shell_args = PackedStringArray(["-c", "cd \"" + project_dir.c_escape() + "\" && uv " + " ".join(quoted_args)])

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
