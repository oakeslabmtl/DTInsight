extends Node

class_name FusekiDataDumper

@onready var file_path_input: TextEdit = $DumpPathEdit
@onready var file_dialog: FileDialog = $FileDialog

# Configuration for dump sections - easier to maintain and extend
const DUMP_CONFIG = [
	{indicator = "Services :", field = "service"},
	{indicator = "Enablers :", field = "enabler"},
	{indicator = "Models :", field = "model"},
	{indicator = "ProvidedThings :", field = "provided_thing"},
	{indicator = "Data transmitted :", field = "data_transmitted"},
	{indicator = "Sensors :", field = "sensing_component"},
	{indicator = "System :", field = "sys_component"},
	{indicator = "System environnement :", field = "env"},
	{indicator = "Data :", field = "data"},
	{indicator = "Rabbit exchange :", field = "rabbit_exchange"},
	{indicator = "Rabbit route :", field = "rabbit_route"},
	{indicator = "Rabbit source :", field = "rabbit_source"},
	{indicator = "Rabbit message listener :", field = "rabbit_message_listener"}
]

# HTML characteristics configuration
const CHARACTERISTICS_CONFIG = [
	{id = "C<sub>1</sub>", name = "System under study", field = "c1", desc_only = true},
	{id = "C<sub>2</sub>", name = "Physical acting components", field = "c2", desc_only = false},
	{id = "C<sub>3</sub>", name = "Physical sensing components", field = "sensing_component", desc_only = false},
	{id = "C<sub>4</sub>", name = "Physical-to-virtual interaction", field = "c4", desc_only = false},
	{id = "C<sub>5</sub>", name = "Virtual-to-physical interaction", field = "c5", desc_only = true},
	{id = "C<sub>6</sub>", name = "DT services", field = "service", desc_only = false},
	{id = "C<sub>7</sub>", name = "Twinning time-scale", field = "c7", desc_only = true},
	{id = "C<sub>8</sub>", name = "Multiplicities", field = "c8", desc_only = true},
	{id = "C<sub>9</sub>", name = "Life-cycle stages", field = "c9", desc_only = true},
	{id = "C<sub>10</sub>", name = "DT models and data", fields = ["model", "data"], desc_only = false, is_composite = true},
	{id = "C<sub>11</sub>", name = "Tooling and enablers", field = "enabler", desc_only = false},
	{id = "C<sub>12</sub>", name = "DT constellation", field = "c12", desc_only = true},
	{id = "C<sub>13</sub>", name = "Twinning process and DT evolution", field = "c13", desc_only = true},
	{id = "C<sub>14</sub>", name = "Fidelity and validity considerations", field = "c14", desc_only = true},
	{id = "C<sub>15</sub>", name = "DT technical connection", field = "c15", desc_only = true},
	{id = "C<sub>16</sub>", name = "DT hosting/deployment", field = "c16", desc_only = true},
	{id = "C<sub>17</sub>", name = "Insights and decision making", field = "provided_thing", desc_only = false},
	{id = "C<sub>18</sub>", name = "Horizontal integration", field = "c18", desc_only = true},
	{id = "C<sub>19</sub>", name = "Data ownership and privacy", field = "c19", desc_only = true},
	{id = "C<sub>20</sub>", name = "Standardization", field = "c20", desc_only = true},
	{id = "C<sub>21</sub>", name = "Security and safety considerations", field = "c21", desc_only = true}
]

var fuseki_data_manager: FusekiData

func set_fuseki_data_manager(manager: FusekiData) -> void:
	fuseki_data_manager = manager

func _on_load_button_pressed() -> void:
	var result = _load_file_content(file_path_input.text)
	if result.success:
		load_from_dump(fuseki_data_manager, result.content)
		print("Data loaded successfully from: ", file_path_input.text)
	else:
		print("Error loading file: ", result.error)

func _on_dump_button_pressed() -> void:
	if not fuseki_data_manager:
		print("Error: No FusekiData manager set")
		return
	
	var result = dump_architecture(fuseki_data_manager, file_path_input.text)
	if result.success:
		print("Data dumped successfully to: ", file_path_input.text)
	else:
		print("Error dumping data: ", result.error)

# Helper function to safely load file content
func _load_file_content(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {success = false, error = "Could not open file: " + path}
	
	var content = file.get_as_text()
	file.close()
	return {success = true, content = content}

# Helper function to safely write file content
func _write_file_content(path: String, content: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return {success = false, error = "Could not create file: " + path}
	
	file.store_string(content)
	file.close()
	return {success = true}

static func dump_characteristics_table(data: FusekiData, dump_path: String, to_console: bool = false) -> Dictionary:
	if not data:
		return {success = false, error = "No data provided"}
	
	var html_content = _build_characteristics_html(data)
	
	if to_console:
		print(html_content)
		return {success = true}
	else:
		var dumper = FusekiDataDumper.new()
		var result = dumper._write_file_content(dump_path, html_content)
		if result.success:
			print("HTML data dumped at: ", dump_path)
		return result

static func _build_characteristics_html(data: FusekiData) -> String:
	var html = PackedStringArray()
	
	html.append("    <table>")
	html.append("        <tr>")
	html.append("            <th></th>")
	html.append("            <th>Characteristics</th>")
	html.append("            <th>Description</th>")
	html.append("        </tr>")
	
	for config in CHARACTERISTICS_CONFIG:
		var description = _get_characteristic_description(data, config)
		html.append(_create_html_table_row(config.id, config.name, description))
	
	html.append("    </table>")
	return "\n".join(html)

static func _get_characteristic_description(data: FusekiData, config: Dictionary) -> String:
	if config.get("is_composite", false):
		# Handle composite fields (like C10 with models and data)
		var parts = PackedStringArray()
		for i in range(config.fields.size()):
			var field_name = config.fields[i]
			var field_data = data.get(field_name)
			var field_label = field_name.capitalize() + ":"
			parts.append(field_label + "<br>" + _format_dictionary_html(field_data, config.desc_only))
		return "<br><br>".join(parts)
	else:
		var field_data = data.get(config.field)
		return _format_dictionary_html(field_data, config.desc_only)

static func _create_html_table_row(id: String, characteristic: String, description: String) -> String:
	return "        <tr>\n            <td class=\"characteristic-id\">" + id + \
		   "</td>\n            <td>" + characteristic + \
		   "</td>\n            <td>" + description + "</td>\n        </tr>"

static func _format_dictionary_html(dict: Dictionary, desc_only: bool = true) -> String:
	if not dict or dict.is_empty():
		return "No data available"
	
	var results = PackedStringArray()
	
	for key in dict.keys():
		var entry = ""
		if not desc_only:
			entry += str(key)
		
		var value = dict[key]
		if value is Dictionary and value.has('desc'):
			if not desc_only:
				entry += ": "
			var desc = str(value['desc']).strip_edges()
			# Clean up array formatting
			desc = desc.replace("[\"", "").replace("\"]", "")
			entry += desc
		
		if not entry.is_empty():
			results.append(entry)
	
	return "<br>".join(results) if not results.is_empty() else "No data available"

static func dump_architecture(data: FusekiData, dump_path: String, to_console: bool = false) -> Dictionary:
	if not data:
		return {success = false, error = "No data provided"}
	
	var dump_content = _build_dump_content(data)
	
	if to_console:
		print(dump_content)
		return {success = true}
	else:
		var dumper = FusekiDataDumper.new()
		return dumper._write_file_content(dump_path, dump_content)

static func _build_dump_content(data: FusekiData) -> String:
	var content = PackedStringArray()
	
	for config in DUMP_CONFIG:
		content.append(config.indicator)
		var field_data = data.get(config.field)
		content.append(_format_dictionary_dump(field_data))
	
	return "\n".join(content)

static func _format_dictionary_dump(dict: Dictionary) -> String:
	var lines = PackedStringArray()
	
	for key in dict.keys():
		lines.append("\t" + key)
		var attributes = dict[key]
		if attributes is Dictionary:
			for attr_key in attributes.keys():
				var attr_value = _array_to_string(attributes[attr_key])
				lines.append("\t\t" + attr_key + " : " + attr_value)
	
	return "\n".join(lines)

static func load_from_dump(fuseki_data: FusekiData, content: String) -> Dictionary:
	if not fuseki_data:
		return {success = false, error = "No FusekiData object provided"}
	
	content = content.replace("\r", "\n")
	var lines = content.split("\n")
	var success = true
	var errors = PackedStringArray()
	
	# Load each section based on configuration
	for i in range(DUMP_CONFIG.size()):
		var current_config = DUMP_CONFIG[i]
		var next_indicator = DUMP_CONFIG[i + 1].indicator if i + 1 < DUMP_CONFIG.size() else ""
		
		var section_data = _extract_section(lines, current_config.indicator, next_indicator)
		if section_data.success:
			fuseki_data.set(current_config.field, section_data.data)
		else:
			success = false
			errors.append("Failed to load " + current_config.field + ": " + section_data.error)
	
	if success:
		FusekiSignals.fuseki_data_updated.emit()
	
	return {success = success, errors = errors}

static func _extract_section(lines: PackedStringArray, start_indicator: String, end_indicator: String) -> Dictionary:
	var start_idx = -1
	var end_idx = lines.size()
	
	# Find start position
	for i in range(lines.size()):
		if lines[i] == start_indicator:
			start_idx = i
			break
	
	if start_idx == -1:
		return {success = false, error = "Start indicator not found: " + start_indicator}
	
	# Find end position
	if not end_indicator.is_empty():
		for i in range(start_idx + 1, lines.size()):
			if lines[i] == end_indicator:
				end_idx = i
				break
	
	var section_lines = lines.slice(start_idx + 1, end_idx)
	return {success = true, data = _parse_dictionary_section(section_lines)}

static func _parse_dictionary_section(lines: PackedStringArray) -> Dictionary:
	var elements = {}
	var current_element = ""
	
	for line in lines:
		var clean_line = line.strip_edges()
		if clean_line.is_empty():
			continue
		
		if line.begins_with("\t\t"):  # Attribute line
			if current_element.is_empty():
				continue  # Skip orphaned attributes
			
			var attr_parts = clean_line.split(" : ", false, 1)
			if attr_parts.size() == 2:
				var attr_name = attr_parts[0].strip_edges()
				var attr_value = _string_to_array(attr_parts[1].strip_edges())
				elements[current_element][attr_name] = attr_value
		
		elif line.begins_with("\t"):  # Element line
			current_element = clean_line
			elements[current_element] = {}
	
	return elements

static func _array_to_string(array: Array) -> String:
	if array.is_empty():
		return ""
	
	var string_array = PackedStringArray()
	for element in array:
		string_array.append(str(element))
	
	return "/".join(string_array)

static func _string_to_array(text: String) -> Array:
	if text.is_empty():
		return []
	return Array(text.split("/"))

# File picker functions
func _on_pick_button_pressed() -> void:
	file_dialog.visible = true

func _on_file_dialog_file_selected(path: String) -> void:
	file_path_input.text = path

func _on_dump_path_edit_focus_entered() -> void:
	CameraSignals.disable_camera_movement.emit()

func _on_dump_path_edit_focus_exited() -> void:
	CameraSignals.enable_camera_movement.emit()
