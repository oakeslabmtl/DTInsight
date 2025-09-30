extends PanelContainer

class_name GenericDisplay

@onready var element : Label = $GenericDisplay/PresentationBox/GenericElementName
@onready var realtime_element : Label = $GenericDisplay/RealTimeContainer/GenericElementAttributes
@onready var script_button = $GenericDisplay/PresentationBox/ScriptButton
@onready var edit_button = $GenericDisplay/PresentationBox/EditButton
@onready var real_time_container = $GenericDisplay/RealTimeContainer
@onready var attributes : Label = $GenericDisplay/RealTimeContainer/GenericElementAttributes
@onready var visualization_container = $GenericDisplay/VisualizationContainer
@onready var pop_up_chart = $PopupChart
@onready var chart = $PopupChart/ChartControl
@onready var pop_up_script = $PopupScript
@onready var script_control = $PopupScript/ScriptControl

var script_software_directory : String = ""
var script_file_path : String = ""
var absolute_path : String = ""
var data : Array = []
var highlightable : bool = true
var bg_color : Color = StyleConfig.DTElement.DIMMED_COLOR
var border_color : Color = StyleConfig.DTElement.BORDER_COLOR

var node_name_before_edit: String
var node_desc_before_edit: String

var last_loaded_pck_path: String = ""

func _ready():
	GenericDisplaySignals.generic_display_highlight.connect(_on_display_highlight)
	ChartSignals.hide.connect(_on_hide_chart_pop_up_signal)
	ScriptSignals.hide.connect(_on_hide_script_pop_up_signal)
	ScriptSignals.scripts_folder_selected.connect(_on_script_folder_updated)
	
	var buttons = get_tree().get_nodes_in_group("main_buttons")
	for btn in buttons:
		if btn.name == "VisualEditingButton":
			btn.toggled.connect(_on_visual_editing_toggled)
			_on_visual_editing_toggled(btn.button_pressed)

#Signal handling ---------------------------------------------------------------
func _on_display_highlight(highlighted_elements_names : Array):
	if (element.text in highlighted_elements_names):
		set_highlight_style()
	else:
		set_default_style()

func _on_mouse_entered():
	GenericDisplaySignals.generic_display_over.emit(element.text, false)

func _on_mouse_exited():
	GenericDisplaySignals.generic_display_over.emit("", false)
	
func _gui_input(event: InputEvent) -> void:
	if event.button_mask == MOUSE_BUTTON_LEFT and highlightable:
		highlightable = false
		GenericDisplaySignals.generic_display_over.emit(element.text, true)
		await get_tree().create_timer(0.2).timeout
		highlightable = true

func _on_pop_up_button_pressed() -> void:
	chart.feed_historic(data)
	pop_up_chart.show()

func _on_hide_chart_pop_up_signal() -> void:
	pop_up_chart.hide()

func _on_script_button_pressed() -> void:
	script_control.set_script_file(absolute_path)
	pop_up_script.show()

func _on_hide_script_pop_up_signal() -> void:
	pop_up_script.hide()

func _on_script_folder_updated(dir : String) -> void:
	script_software_directory = dir
	set_python_script()

func _on_visual_editing_toggled(enabled: bool):
	if enabled:
		edit_button.show()
	else:
		edit_button.hide()

 #Trigger the file dialog when the button is pressed
func _on_viz_picker_button_pressed() -> void:
	var file_picker = $GenericDisplay/FilePicker
	file_picker.popup_centered()

# Handle file selection and load the .pck
func _on_file_selected(pck_path: String) -> void:
	last_loaded_pck_path = pck_path
	if not last_loaded_pck_path.is_empty():
		$GenericDisplay/VisualizationContainer/HBoxContainer/VizPopUpButton.disabled = false

func _on_edit_button_pressed() -> void:
	$PopupDescription.popup()

func _on_popup_description_about_to_popup() -> void:
	CameraSignals.disable_camera_movement.emit()
	CameraSignals.disable_camera_zoom.emit()
	# Save current variables
	node_name_before_edit = $GenericDisplay/PresentationBox/GenericElementName.text
	
func _on_popup_description_popup_hide() -> void:
	CameraSignals.enable_camera_movement.emit()
	CameraSignals.enable_camera_zoom.emit()
	
	# Emit signal to edit the node's FusekiData
	var node_name = $GenericDisplay/PresentationBox/GenericElementName.text
	var node_desc = $PopupDescription/DescriptionControl/DescriptionContainer/Description.text
	var parent_container = get_parent()
	# Edit the descirption
	GenericDisplaySignals.generic_display_edit.emit(node_name_before_edit, parent_container, false, node_name, node_desc)

func _on_viz_pop_up_button_pressed():
	var pop_up_panel = $GenericDisplay/VisualizationContainer/HBoxContainer/VizPopUpButton/PopupPanel
	var pop_up_panel_3d_root = %popup_root

	# Clear the pop up panel
	for child in pop_up_panel_3d_root.get_children():
		pop_up_panel_3d_root.remove_child(child)
		child.queue_free()

	# Load the selected .pck file
	var success := ProjectSettings.load_resource_pack(last_loaded_pck_path)
	if not success:
		push_error("Failed to load .pck file: %s" % last_loaded_pck_path)
		return

	var pop_up_scene_path := "res://main.tscn"
	var pop_up_scene = load(pop_up_scene_path).instantiate()
	pop_up_panel_3d_root.add_child(pop_up_scene)

	if not OS.has_feature("web"):
		if RabbitMq.is_connected("OnMessage", Callable(pop_up_scene, "_on_message")) == false:
			RabbitMq.connect("OnMessage", Callable(pop_up_scene, "_on_message"))

	pop_up_panel.show()

#Informations ------------------------------------------------------------------
func set_text(text : String) -> void:
	var node : Label = $GenericDisplay/PresentationBox/GenericElementName
	node.text = text

func set_python_script_location(path : String) -> void:
	if not OS.has_feature("web"):
		script_file_path = path
		set_python_script()

func set_python_script() -> void:
	if (not script_file_path.is_empty()):
		var folder_path = script_software_directory if (script_software_directory != "") else PythonConfig.SOFTWARE_PATH
		absolute_path = folder_path + "/" + script_file_path
		var script_name = script_file_path.split("/")[script_file_path.split("/").size() - 1]
		var python_button : Button = get_node("GenericDisplay/PresentationBox/ScriptButton")
		python_button.text = script_name
		python_button.show()

func set_visualization():
	if not OS.has_feature("web"):
		$GenericDisplay/VisualizationContainer.show()
		if last_loaded_pck_path.is_empty():
			$GenericDisplay/VisualizationContainer/HBoxContainer/VizPopUpButton.disabled = true

# Enables a button showing DTComponent information
func set_description(description):
	tooltip_text = description
	$PopupDescription/DescriptionControl/DescriptionContainer/ComponentNameContainer/ComponentNameEdit.text = $GenericDisplay/PresentationBox/GenericElementName.text
	$PopupDescription/DescriptionControl/DescriptionContainer/Description.text = description
	$PopupDescription/DescriptionControl/DescriptionContainer/ComponentNameContainer/ComponentNameEdit.grab_focus()

# Editable component name
func _on_component_name_edit_text_changed() -> void:
	$GenericDisplay/PresentationBox/GenericElementName.text = $PopupDescription/DescriptionControl/DescriptionContainer/ComponentNameContainer/ComponentNameEdit.text

# Editable component description
func _on_description_text_changed() -> void:
	tooltip_text = $PopupDescription/DescriptionControl/DescriptionContainer/Description.text

func set_info(new_data : Array[String], is_bool = false) -> void:
	data = to_float_array(new_data, is_bool)
	var node : Label = get_node("GenericDisplay/RealTimeContainer/GenericElementAttributes")
	var last_data = data[data.size() - 1]
	var info : String
	if is_bool:
		if last_data == 1:
			info = "on"
		else:
			info = "off"
	else:
		info = format_float(last_data, 4)
	node.text = "Real time info : \n" + info
	var real_time : VBoxContainer = get_node("GenericDisplay/RealTimeContainer")
	real_time.visible = false if (info.is_empty()) else true
	update_chart(last_data)

func to_float_array(str_array : Array[String], is_bool) -> Array:
	if is_bool:
		var int_array : Array = str_array.map(func(s) -> float : return float(s == "true")) as Array[float]
		return int_array
	else :
		var int_array : Array = str_array.map(func(s) -> float : return float(s)) as Array[float]
		return int_array

func format_float(f: float, sig_digits: int = 4) -> String:
	if f == 0.0:
		return "0"

	var abs_f = abs(f)
	var exponent = floor(log(abs_f) / log(10))
	var _scale = pow(10, sig_digits - 1 - exponent)
	var rounded = round(f * _scale) / _scale

	var result = String.num(rounded, 10)

	if "." in result:
		result = result.rstrip("0").rstrip(".")
	
	return result

func update_chart(last_data) -> void:
	if pop_up_chart.visible == false :
		return
	if not chart.up_to_date:
		chart.feed_historic(data)
	else :
		chart.add_value(last_data)

# Style --------------------------------------------------------------
## Highlights
func set_default_style():
	change_bg_color(bg_color)
	change_border_color(border_color)
	change_text_color(Color.BLACK)

func set_highlight_style():
	change_bg_color(StyleConfig.DTElement.HIGHLIGHT_COLOR)
	change_text_color(StyleConfig.DTElement.TEXT_HIGHLIGHT_COLOR)

## Changing styles
func change_bg_color(color : Color):
	var styleBox : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	styleBox.bg_color = color
	add_theme_stylebox_override("panel", styleBox)
	
func change_border_color(color : Color):
	var styleBox : StyleBoxFlat = get_theme_stylebox("panel").duplicate()
	styleBox.border_color = color
	styleBox.set_border_width_all(StyleConfig.DTElement.BORDER_WIDTH)
	add_theme_stylebox_override("panel", styleBox)
	
func change_text_color(color: Color):
	element.set("theme_override_colors/font_color", color)
	realtime_element.set("theme_override_colors/font_color", color)

## Style definitions
func set_node_style(_color: Color, is_bg: bool, is_border: bool):
	if  is_bg:
		bg_color = _color
		change_bg_color(bg_color)
	if is_border:
		border_color = _color
		change_border_color(border_color)

func _on_delete_button_pressed() -> void:
	var node_name = $GenericDisplay/PresentationBox/GenericElementName.text
	var parent_container = get_parent()
	GenericDisplaySignals.generic_display_edit.emit(node_name, parent_container, true, "", "")
	CameraSignals.enable_camera_movement.emit()
	CameraSignals.enable_camera_zoom.emit()
	queue_free()
