## Handles persisting and loading FusekiData to/from disk.
##
## Two output formats are supported:
##   • YAML-like architecture dump  — plain-text, one line per attribute.
##   • HTML characteristics table  — a <table> fragment for embedding in reports.
##
## Both formats can also be printed to the Godot console (to_console = true).
##
## Loading (load_from_dump) is the reverse of the YAML dump: it reads the
## plain-text file back and reconstructs the FusekiData dictionaries.

extends Node

class_name FusekiDataDumper

@onready var file_path_input: TextEdit = $DumpPathEdit
@onready var file_dialog: FileDialog   = $FileDialog

var fuseki_data_manager: FusekiData


# ── Configuration tables ───────────────────────────────────────────────────────

## Drives both dump_architecture and load_from_dump.
## Each entry maps a section header string to a FusekiData field name.
## Order matters: load_from_dump uses adjacent indicators to delimit sections.
const DUMP_CONFIG := [
	{indicator = "Services :",           field = "service"},
	{indicator = "Enablers :",           field = "enabler"},
	{indicator = "Models :",             field = "model"},
	{indicator = "ProvidedThings :",     field = "provided_thing"},
	{indicator = "Data transmitted :",   field = "data_transmitted"},
	{indicator = "Sensors :",            field = "sensing_component"},
	{indicator = "System :",             field = "sys_component"},
	{indicator = "System environnement :", field = "env"},
	{indicator = "Data :",               field = "data"},
	{indicator = "Rabbit exchange :",    field = "rabbit_exchange"},
	{indicator = "Rabbit route :",       field = "rabbit_route"},
	{indicator = "Rabbit source :",      field = "rabbit_source"},
	{indicator = "Rabbit message listener :", field = "rabbit_message_listener"},
]

## Drives dump_characteristics_table. Each entry describes one row in the HTML table.
## Fields:
##   id         — HTML string for the characteristic id cell (may contain <sub>).
##   name       — Human-readable characteristic name.
##   field      — FusekiData member to read (or 'fields' for composite entries).
##   desc_only  — When true, only the 'desc' attribute is shown (no entity names).
##   is_composite (optional) — When true, 'fields' (Array) is used instead of 'field'.
const CHARACTERISTICS_CONFIG := [
	{id = "C<sub>1</sub>",  name = "System under study",                    field = "c1",               desc_only = true},
	{id = "C<sub>2</sub>",  name = "Physical acting components",            field = "c2",               desc_only = false},
	{id = "C<sub>3</sub>",  name = "Physical sensing components",           field = "sensing_component",desc_only = false},
	{id = "C<sub>4</sub>",  name = "Physical-to-virtual interaction",       field = "c4",               desc_only = false},
	{id = "C<sub>5</sub>",  name = "Virtual-to-physical interaction",       field = "c5",               desc_only = true},
	{id = "C<sub>6</sub>",  name = "DT services",                          field = "service",          desc_only = false},
	{id = "C<sub>7</sub>",  name = "Twinning time-scale",                  field = "c7",               desc_only = true},
	{id = "C<sub>8</sub>",  name = "Multiplicities",                       field = "c8",               desc_only = true},
	{id = "C<sub>9</sub>",  name = "Life-cycle stages",                    field = "c9",               desc_only = true},
	{id = "C<sub>10</sub>", name = "DT models and data",  fields = ["model", "data"], desc_only = false, is_composite = true},
	{id = "C<sub>11</sub>", name = "Tooling and enablers",                 field = "enabler",          desc_only = false},
	{id = "C<sub>12</sub>", name = "DT constellation",                     field = "c12",              desc_only = true},
	{id = "C<sub>13</sub>", name = "Twinning process and DT evolution",    field = "c13",              desc_only = true},
	{id = "C<sub>14</sub>", name = "Fidelity and validity considerations", field = "c14",              desc_only = true},
	{id = "C<sub>15</sub>", name = "DT technical connection",              field = "c15",              desc_only = true},
	{id = "C<sub>16</sub>", name = "DT hosting/deployment",               field = "c16",              desc_only = true},
	{id = "C<sub>17</sub>", name = "Insights and decision making",         field = "provided_thing",   desc_only = false},
	{id = "C<sub>18</sub>", name = "Horizontal integration",              field = "c18",              desc_only = true},
	{id = "C<sub>19</sub>", name = "Data ownership and privacy",          field = "c19",              desc_only = true},
	{id = "C<sub>20</sub>", name = "Standardization",                     field = "c20",              desc_only = true},
	{id = "C<sub>21</sub>", name = "Security and safety considerations",  field = "c21",              desc_only = true},
]


# ── Lifecycle ─────────────────────────────────────────────────────────────────

## Injects the shared [FusekiData] manager used by button-driven operations.
func set_fuseki_data_manager(manager: FusekiData) -> void:
	fuseki_data_manager = manager


# ── Button callbacks ──────────────────────────────────────────────────────────

func _on_load_button_pressed() -> void:
	var result := _load_file_content(file_path_input.text)
	if result.success:
		load_from_dump(fuseki_data_manager, result.content)
		print("Data loaded successfully from: ", file_path_input.text)
	else:
		push_error("FusekiDumper: Error loading file: " + result.error)


func _on_dump_button_pressed() -> void:
	if not fuseki_data_manager:
		push_error("FusekiDumper: No FusekiData manager set")
		return

	var result := dump_architecture(fuseki_data_manager, file_path_input.text)
	if result.success:
		print("Data dumped successfully to: ", file_path_input.text)
	else:
		push_error("FusekiDumper: Error dumping data: " + result.error)


# ── File I/O helpers ──────────────────────────────────────────────────────────

## Returns {success, content} or {success, error}.
func _load_file_content(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {success = false, error = "Could not open file: " + path}
	var content := file.get_as_text()
	file.close()
	return {success = true, content = content}


## Returns {success} or {success, error}.
func _write_file_content(path: String, content: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return {success = false, error = "Could not create file: " + path}
	file.store_string(content)
	file.close()
	return {success = true}


# ── HTML characteristics table ────────────────────────────────────────────────

## Builds and writes (or prints) an HTML <table> fragment containing one row
## per DTDF characteristic. Returns {success} or {success, error}.
static func dump_characteristics_table(data: FusekiData, dump_path: String, to_console: bool = false) -> Dictionary:
	if not data:
		return {success = false, error = "No data provided"}

	var html_content := _build_characteristics_html(data)

	if to_console:
		print(html_content)
		return {success = true}
	else:
		var dumper := FusekiDataDumper.new()
		var result := dumper._write_file_content(dump_path, html_content)
		if result.success:
			print("HTML characteristics table written to: ", dump_path)
		return result


static func _build_characteristics_html(data: FusekiData) -> String:
	var html := PackedStringArray()
	html.append("""    <table>
        <tr>
            <th></th>
            <th>Characteristics</th>
            <th>Description</th>
		</tr>""")

	for config in CHARACTERISTICS_CONFIG:
		var description := _get_characteristic_description(data, config)
		html.append(_create_html_table_row(config.id, config.name, description))

	html.append("    </table>")
	return "\n".join(html)


## Resolves the description cell content for a single characteristic config entry.
static func _get_characteristic_description(data: FusekiData, config: Dictionary) -> String:
	if config.get("is_composite", false):
		# Composite characteristic (e.g. C10: models + data): render each sub-field
		# as a labelled block separated by a blank line.
		var parts := PackedStringArray()
		for field_name in config.fields:
			var field_data = data.get(field_name)
			var label = field_name.capitalize() + ":"
			parts.append(label + "<br>" + _format_dictionary_html(field_data, config.desc_only))
		return "<br><br>".join(parts)
	else:
		var field_data = data.get(config.field)
		return _format_dictionary_html(field_data, config.desc_only)


static func _create_html_table_row(id: String, characteristic: String, description: String) -> String:
	return """        <tr>
			<td class="characteristic-id">%s</td>
            <td>%s</td>
            <td>%s</td>
		</tr>""" % [id, characteristic, description]


## Formats a FusekiData entity dictionary as HTML.
## When [param desc_only] is true, only the 'desc' attribute value is shown;
## otherwise the entity name is prepended.
static func _format_dictionary_html(dict: Dictionary, desc_only: bool = true) -> String:
	if not dict or dict.is_empty():
		return "No data available"

	var results := PackedStringArray()
	for key in dict.keys():
		var entry := ""
		if not desc_only:
			entry += str(key)

		var value = dict[key]
		if value is Dictionary and value.has("desc"):
			if not desc_only:
				entry += ": "
			# Strip surrounding array brackets from the stored string value.
			var desc: String = str(value["desc"]).strip_edges()
			desc = desc.replace("[\"", "").replace("\"]", "")
			entry += desc

		if not entry.is_empty():
			results.append(entry)

	return "<br>".join(results) if not results.is_empty() else "No data available"


# ── YAML-like architecture dump ───────────────────────────────────────────────

## Builds and writes (or prints) a plain-text architecture dump of all DTDF
## entities in [param data]. Returns {success} or {success, error}.
static func dump_architecture(data: FusekiData, dump_path: String, to_console: bool = false) -> Dictionary:
	if not data:
		return {success = false, error = "No data provided"}

	var dump_content := _build_dump_content(data)

	if to_console:
		print(dump_content)
		return {success = true}
	else:
		var dumper := FusekiDataDumper.new()
		return dumper._write_file_content(dump_path, dump_content)


static func _build_dump_content(data: FusekiData) -> String:
	var content := PackedStringArray()
	for config in DUMP_CONFIG:
		content.append(config.indicator)
		var field_data = data.get(config.field)
		content.append(_format_dictionary_dump(field_data))
	return "\n".join(content)


## Serialises one entity dictionary to indented plain text:
##   \t<entity_name>
##   \t\t<attribute> : <value1>/<value2>/...
static func _format_dictionary_dump(dict: Dictionary) -> String:
	var lines := PackedStringArray()
	for key in dict.keys():
		lines.append("\t" + key)
		var attributes = dict[key]
		if attributes is Dictionary:
			for attr_key in attributes.keys():
				var attr_value := _array_to_string(attributes[attr_key])
				lines.append("\t\t" + attr_key + " : " + attr_value)
	return "\n".join(lines)


# ── Load from dump ────────────────────────────────────────────────────────────

## Parses a previously written architecture dump string back into [param fuseki_data].
## Emits FusekiSignals.fuseki_data_updated on success.
## Returns {success, errors} where errors is a PackedStringArray of per-section messages.
static func load_from_dump(fuseki_data: FusekiData, content: String) -> Dictionary:
	if not fuseki_data:
		return {success = false, error = "No FusekiData object provided"}

	# Normalise line endings before splitting.
	content = content.replace("\r", "\n")
	var lines := content.split("\n")
	var success := true
	var errors := PackedStringArray()

	for i in range(DUMP_CONFIG.size()):
		var current_config = DUMP_CONFIG[i]
		# Use the next section's indicator as the end boundary (empty string for last section).
		var next_indicator: String = DUMP_CONFIG[i + 1].indicator if i + 1 < DUMP_CONFIG.size() else ""

		var section_data := _extract_section(lines, current_config.indicator, next_indicator)
		if section_data.success:
			fuseki_data.set(current_config.field, section_data.data)
		else:
			success = false
			errors.append("Failed to load '" + current_config.field + "': " + section_data.error)

	if success:
		FusekiSignals.fuseki_data_updated.emit()

	return {success = success, errors = errors}


## Extracts the lines belonging to one dump section, delimited by indicator strings.
## Returns {success, data} or {success, error}.
static func _extract_section(lines: PackedStringArray, start_indicator: String, end_indicator: String) -> Dictionary:
	var start_idx := -1
	var end_idx := lines.size()

	# Locate the start indicator line.
	for i in range(lines.size()):
		if lines[i] == start_indicator:
			start_idx = i
			break

	if start_idx == -1:
		return {success = false, error = "Start indicator not found: " + start_indicator}

	# Locate the end indicator (next section header), if one exists.
	if not end_indicator.is_empty():
		for i in range(start_idx + 1, lines.size()):
			if lines[i] == end_indicator:
				end_idx = i
				break

	var section_lines := lines.slice(start_idx + 1, end_idx)
	return {success = true, data = _parse_dictionary_section(section_lines)}


## Reconstructs an entity dictionary from a slice of indented dump lines.
## Lines starting with two tabs are attribute lines; one tab = entity name.
static func _parse_dictionary_section(lines: PackedStringArray) -> Dictionary:
	var elements: Dictionary = {}
	var current_element := ""

	for line in lines:
		var clean_line := line.strip_edges()
		if clean_line.is_empty():
			continue

		if line.begins_with("\t\t"):  # Attribute line
			if current_element.is_empty():
				continue  # Skip attributes that appear before any entity header.
			var attr_parts := clean_line.split(" : ", false, 1)
			if attr_parts.size() == 2:
				var attr_name  := attr_parts[0].strip_edges()
				var attr_value := _string_to_array(attr_parts[1].strip_edges())
				elements[current_element][attr_name] = attr_value

		elif line.begins_with("\t"):  # Entity name line
			current_element = clean_line
			elements[current_element] = {}

	return elements


# ── Serialisation helpers ─────────────────────────────────────────────────────

## Joins an array of values with '/' for compact single-line storage.
static func _array_to_string(array: Array) -> String:
	if array.is_empty():
		return ""
	var string_array := PackedStringArray()
	for element in array:
		string_array.append(str(element))
	return "/".join(string_array)


## Splits a '/' -delimited string back into an Array. Returns [] for empty input.
static func _string_to_array(text: String) -> Array:
	if text.is_empty():
		return []
	return Array(text.split("/"))


# ── File-picker UI callbacks ───────────────────────────────────────────────────

func _on_pick_button_pressed() -> void:
	file_dialog.visible = true


func _on_file_dialog_file_selected(path: String) -> void:
	file_path_input.text = path


## Lock camera movement while the path TextEdit has focus so keyboard input
## is not inadvertently captured by the camera controller.
func _on_dump_path_edit_focus_entered() -> void:
	CameraSignals.disable_camera_movement.emit()


func _on_dump_path_edit_focus_exited() -> void:
	CameraSignals.enable_camera_movement.emit()
