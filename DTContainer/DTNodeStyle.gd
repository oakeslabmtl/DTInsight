## Utility class for applying visual styles to GenericDisplay nodes.
## All methods are static — no instance state needed.
class_name DTNodeStyle

const TIMESCALE_KEY := "hasTimeScale"
const IMPLEMENTATION_KEY := "hasImplementation"
const TYPE_ATTRIBUTE := "type"
const OPERATOR_TYPE := "Insight"

const GenericDisplayScene = preload("res://GenericDisplay/generic_display.tscn")


## Apply structural and visual styles to a node based on its Fuseki attributes.
static func apply_style(node: GenericDisplay, attributes: Dictionary,
		bg_view: int, border_view: int, timescale_colors: Dictionary) -> void:
	# Structural properties
	if PythonConfig.LOCATION_KEY in attributes:
		node.set_python_script_location(attributes[PythonConfig.LOCATION_KEY][0])
	if "HasVisualization" in attributes and attributes["HasVisualization"][0] == "true":
		node.set_visualization()
	if "desc" in attributes and attributes["desc"][0] != "":
		node.set_description(attributes["desc"][0])
	else:
		node.set_description("")

	# Base visual style
	node.set_default_style()
	node.set_node_style(StyleConfig.DTElement.DIMMED_COLOR, true, false)
	node.set_node_style(StyleConfig.DTElement.BORDER_COLOR, false, true)

	# Implementation-based coloring
	if IMPLEMENTATION_KEY in attributes:
		var is_border = border_view == 2
		var is_bg = bg_view == 2
		match attributes[IMPLEMENTATION_KEY]:
			["planned"]:
				node.set_node_style(StyleConfig.Implementation.PLANNED, is_bg, is_border)
			["active"]:
				node.set_node_style(StyleConfig.Implementation.ACTIVE, is_bg, is_border)
			["implemented"]:
				node.set_node_style(StyleConfig.Implementation.IMPLEMENTED, is_bg, is_border)
	# Timescale-based coloring
	elif TIMESCALE_KEY in attributes:
		var is_border = border_view == 3
		var is_bg = bg_view == 3
		var attr = attributes[TIMESCALE_KEY][0]
		if attr in timescale_colors:
			node.set_node_style(timescale_colors[attr], is_bg, is_border)


## Populate a visual container with GenericDisplay nodes from Fuseki data.
## Creates new nodes for keys not yet displayed; updates existing ones.
static func populate_container(container: HBoxContainer, fuseki_node_data: Dictionary,
		displayed_node_list: Array[Node], bg_view: int, border_view: int,
		timescale_colors: Dictionary) -> void:
	for key in fuseki_node_data:
		var existing = find_node_by_name(displayed_node_list, key)
		if existing == null:
			var new_node: GenericDisplay = GenericDisplayScene.instantiate()
			new_node.name = key
			new_node.set_text(key)
			container.add_child(new_node)
			displayed_node_list.append(new_node)
			apply_style(new_node, fuseki_node_data[key], bg_view, border_view, timescale_colors)
		else:
			apply_style(existing, fuseki_node_data[key], bg_view, border_view, timescale_colors)


## Split provided-thing data into Operator vs Machine and populate both containers.
static func populate_provided_things(operator_ctr: HBoxContainer,
		machine_ctr: HBoxContainer, provided_data: Dictionary,
		displayed_node_list: Array[Node], bg_view: int, border_view: int,
		timescale_colors: Dictionary) -> void:
	var operator_data := {}
	var machine_data := {}
	for entry_name in provided_data:
		if TYPE_ATTRIBUTE in provided_data[entry_name]:
			if OPERATOR_TYPE in provided_data[entry_name][TYPE_ATTRIBUTE]:
				operator_data[entry_name] = provided_data[entry_name]
			else:
				machine_data[entry_name] = provided_data[entry_name]
	populate_container(operator_ctr, operator_data, displayed_node_list, bg_view, border_view, timescale_colors)
	populate_container(machine_ctr, machine_data, displayed_node_list, bg_view, border_view, timescale_colors)


## Find a GenericDisplay node by name in the displayed node list.
static func find_node_by_name(node_list: Array[Node], node_name: String) -> GenericDisplay:
	for node in node_list:
		if node != null and node.name == node_name:
			return node
	return null


## Free all PanelContainer children of a node.
static func free_all_child(node: Node) -> void:
	for child in node.get_children():
		if child.get_class() == "PanelContainer":
			child.queue_free()
