extends Control

class_name DT_PT

#Getting ready and general variables ---------------------------------------------------------------
#Reference each visual data container
@onready var service_container = $DTContainer/ServicesPanel/ServicesOrganizer/ServicesContainer
@onready var enabler_container = $DTContainer/EnablersPanel/EnablerOrganizer/EnablersContainer
@onready var model_container = $DTContainer/ModelsDataPanel/ModelsDataContainer/ModelsPanelContainer/ModelsContainer
@onready var data_container = $DTContainer/ModelsDataPanel/ModelsDataContainer/DataPanelContainer/DataContainer
@onready var operator_container = $"PTContainer/Operator&EnvContainer/OperatorPanel/OperatorOrganizer/OperatorContainer"
@onready var machine_container = $PTContainer/DataTravelContainer/MachinePanel/MachineOrganizer/MachineContainer
@onready var data_transmitted_container = $PTContainer/DataTravelContainer/DataOutPanel/DataOutContainer/DataTransmittedOrganizer/DataTransmittedContainer
@onready var sensor_container = $PTContainer/DataTravelContainer/DataOutPanel/DataOutContainer/SensorsOrganizer/SensorsContainer
@onready var env_container = $"PTContainer/Operator&EnvContainer/ExperimentContainer/EnvPanel/EnvOrganizer/EnvContainer"
@onready var sys_container = $"PTContainer/Operator&EnvContainer/ExperimentContainer/SystemPanel/SystemOrganizer/SystemContainer"

#Access to fuseki data
var fuseki_data : FusekiData = null

#Load the generic display scene
const GenericDisplay = preload("res://GenericDisplay/generic_display.tscn")

#name of highlighted element
var highlighted_element = null
var all_highlighted_element = []
var highlighted_with_click = false

# Border and background views
var bg_view = 0
var border_view = 0

#initialization
func _ready():
	GenericDisplaySignals.generic_display_over.connect(_on_element_over)
	RabbitSignals.updated_data.connect(_on_rabbit_data_updated)

#Node and element manipulation functions -----------------------------------------------------------

#Displays node referenced by its name
class NamedNode:
	var name : String
	var node : GenericDisplay

#Array of displayes nodes
var displayed_node_list: Array[NamedNode]

#Attributes
const timescale_key : String = "hasTimeScale"
const implementation_key : String = "hasImplementation"
const type_attribute : String = "type"

#Operator/machine
const operator_type : String = "Insight"

#Set the starting start of a node when loaded
func set_starting_node_style(namedNode : NamedNode, attributes : Dictionary):
	# Structural style
	if (PythonConfig.LOCATION_KEY in attributes.keys()):
		namedNode.node.set_python_script_location(attributes[PythonConfig.LOCATION_KEY][0])
	if ("HasVisualization" in attributes.keys() and attributes["HasVisualization"][0] == "true"):
		namedNode.node.set_visualization()
	if ("desc" in attributes.keys() and attributes["desc"][0] != ""):
		namedNode.node.set_description(attributes["desc"][0])
	# Visual style
	namedNode.node.set_default_style()
	if (implementation_key in attributes.keys()):
		var is_border = border_view == 2
		var is_bg = bg_view == 2
		match attributes[implementation_key]:
			["planned"]:
				namedNode.node.set_node_style(StyleConfig.Implementation.PLANNED, is_bg, is_border)
			["active"]:
				namedNode.node.set_node_style(StyleConfig.Implementation.ACTIVE, is_bg, is_border)
			["implemented"]:
				namedNode.node.set_node_style(StyleConfig.Implementation.IMPLEMENTED, is_bg, is_border)
	if (timescale_key in attributes.keys()):
		var is_border = border_view == 3
		var is_bg = bg_view == 3
		match attributes[timescale_key]:
			["slower_trt"]:
				namedNode.node.set_node_style(StyleConfig.Timescale.SLOWER_THAN_REALTIME, is_bg, is_border)
			["rt"]:
				namedNode.node.set_node_style(StyleConfig.Timescale.REALTIME, is_bg, is_border)
			["faster_trt"]:
				namedNode.node.set_node_style(StyleConfig.Timescale.FASTER_THAN_REALTIME, is_bg, is_border)

#Set highlighted element on signal
func _on_element_over(element_name, click: bool):
	if element_name == "":
		if not click and highlighted_with_click:
			return
		elif click:
			highlighted_with_click = false
		highlighted_element = null
		all_highlighted_element = []
		GenericDisplaySignals.generic_display_highlight.emit([])
	else:
		if click:
			# Clicking again on an highlighted node deactivates highlights
			if element_name in all_highlighted_element and highlighted_with_click:
				highlighted_element = null
				all_highlighted_element = []
				GenericDisplaySignals.generic_display_highlight.emit([])
				highlighted_with_click = false
				return
			else:
				highlighted_element = get_node_by_name(element_name)
				all_highlighted_element = get_all_connected_to(element_name)
				GenericDisplaySignals.generic_display_highlight.emit(all_highlighted_element)
				highlighted_with_click = true
				return
		# If mouse exits and nothing was highlighted by click
		if not highlighted_with_click:
			highlighted_element = get_node_by_name(element_name)
			all_highlighted_element = get_all_connected_to(element_name)
			GenericDisplaySignals.generic_display_highlight.emit(all_highlighted_element)

#Return a node by its name in the displayes_node_list
func get_node_by_name(node_name : String) -> GenericDisplay:
	for displayed_node in displayed_node_list:
		if (displayed_node.name == node_name && displayed_node.node != null):
			return displayed_node.node
	var displayed_node_list_string = ""
	for displayed_node in displayed_node_list:
		displayed_node_list_string += displayed_node.name
	print(node_name + " not found in " + displayed_node_list_string)
	return null

#Get a list of elements connected to inputed element
func get_all_connected_to(element_name : String) -> Array[String]:
	var all_connected : Array[String]= [element_name]
	var all_links = fuseki_data.enabler_to_service + fuseki_data.model_to_enabler + fuseki_data.service_to_provided_thing + fuseki_data.sensor_to_data_transmitted + fuseki_data.data_transmitted_to_data + fuseki_data.data_to_enabler
	for link in all_links:
		if link.source == element_name:
			all_connected.append(link.destination)
		if link.destination == element_name:
			all_connected.append(link.source)
	return all_connected

#Return middle position of a node on the x axis
static func get_middle_x(node) -> int:
	var node_position = node.global_position
	var node_size = node.size
	return node_position.x + node_size.x / 2 - StyleConfig.Link.WIDTH / 2

#Return middle bottom position of a node
func get_bottom_side(node) -> Vector2:
	var node_position = node.global_position
	var node_size = node.size
	var corrected_position = Vector2(DT_PT.get_middle_x(node), node_position.y + node_size.y)
	return corrected_position

#Return middle top position of a node
func get_top_side(node) -> Vector2:
	var node_position = node.global_position
	var corrected_position = Vector2(DT_PT.get_middle_x(node), node_position.y)
	return corrected_position

#Link manipulation and display functions -----------------------------------------------------------

#Container side enum
enum ContainerSide {
  TOP,
  BOTTOM,
  ANY
}

#displayed coordinates collection
var already_drawn_x : Array[int] = []
var already_drawn_y : Array[int] = []

#display list
var dimmed_lines : Array[Dictionary] = []
var highlighted_lines : Array[Dictionary] = []
var dimmed_triangles : Array[Dictionary] = []
var highlighted_triangles : Array[Dictionary] = []

#Add lines to call list
func draw_line_differed(start: Vector2, end: Vector2, color: Color, width : int, antialiased: bool):
	if (color == StyleConfig.Link.DIMMED_COLOR):
		dimmed_lines.append({
			"start": start,
			"end": end,
			"color": color,
			"width": width,
			"antialiased": antialiased
			})
	else :
		highlighted_lines.append({
			"start": start,
			"end": end,
			"color": color,
			"width": width,
			"antialiased": antialiased
			})

#Add triangles to call list
func draw_triangle_differed(aimed_at : Vector2, color : Color, is_pointing_up : bool) -> int:
	var vertical_shift = StyleConfig.Link.WIDTH if is_pointing_up else - StyleConfig.Link.WIDTH
	if (color == StyleConfig.Link.DIMMED_COLOR):
		dimmed_triangles.append({
			"aimed_at": aimed_at,
			"vertical_shift": vertical_shift,
			"color": color,
			"is_pointing_up": is_pointing_up
		})
	else :
		highlighted_triangles.append({
			"aimed_at": aimed_at,
			"vertical_shift": vertical_shift,
			"color": color,
			"is_pointing_up": is_pointing_up
		})
	return vertical_shift

#Draw all differed call list
func draw_all_differed():
	var lines_draw_list = dimmed_lines + highlighted_lines
	for line in lines_draw_list:
		draw_line(line["start"], line["end"], line["color"], line["width"], line["antialiased"])
	var triangles_draw_list = dimmed_triangles + highlighted_triangles
	for triangle in triangles_draw_list:
		draw_triangle(triangle["aimed_at"], triangle["vertical_shift"], triangle["color"], triangle["is_pointing_up"])

#Update operator container and machine container, differenciate on attibute
func update_provided_things(operator_container : HBoxContainer, machine_container : HBoxContainer, provided_data : Dictionary):
	var operator_data : Dictionary = {}
	var machine_data : Dictionary = {}
	for entry_name in provided_data.keys():
		if (type_attribute in provided_data[entry_name].keys()):
			if (operator_type in provided_data[entry_name][type_attribute]):
				operator_data[entry_name] = provided_data[entry_name]
			else:
				machine_data[entry_name] = provided_data[entry_name]
	update_node_with(operator_container, operator_data)
	update_node_with(machine_container, machine_data)

#Update a node with Fuseki element data by creating a generic display node
func update_node_with(visual_container : HBoxContainer, fuseki_node_data : Dictionary):
	DT_PT.free_all_child(visual_container)
	for key in fuseki_node_data.keys():
		var new_node = GenericDisplay.instantiate()
		new_node.set_text(key)
		visual_container.add_child(new_node)
		var displayed_element = NamedNode.new()
		displayed_element.name = key
		displayed_element.node = new_node
		displayed_node_list.append(displayed_element)
		set_starting_node_style(displayed_element, fuseki_node_data[key])

#Transform fuseki link data (a list a link) to a dictionary
func to_link_dictionary(fuseki_link_data) -> Dictionary:
	var links : Dictionary = {} #desination as key -> list 
	for link in fuseki_link_data:
		var source_node = get_node_by_name(link.source)
		if(not links.has(source_node)):
			links[source_node] = []
		links[source_node].append(get_node_by_name(link.destination))
	return links

#Return true if link in highlighted path
func in_critical_path(source, destinations : Array) -> bool:
	return (highlighted_element == null or source == highlighted_element or highlighted_element in destinations)

#Return color for link depending on its conditions
func get_appropriate_link_color(is_in_critical_path : bool):
	return StyleConfig.Link.HIGHLIGHT_COLOR if is_in_critical_path else StyleConfig.Link.DIMMED_COLOR

#Draw from element node on y axis to linking lane on x axis, with an arrow if destination of link
func draw_element_to_lane(node, drawable_y_position : int, color : Color, destination : bool = false) -> int:
	var is_pointing_up : bool = node.global_position.y < drawable_y_position
	var drawing_position_element : Vector2 = get_bottom_side(node) if (is_pointing_up) else get_top_side(node)
	var adjusted_x : int = get_drawable_x_position(drawing_position_element.x)
	var vertical_shift : int = draw_triangle_differed(Vector2(adjusted_x, drawing_position_element.y), color, is_pointing_up) if destination else 0
	draw_line_differed(Vector2(adjusted_x, drawing_position_element.y + vertical_shift), Vector2(adjusted_x, drawable_y_position), color, StyleConfig.Link.WIDTH, true)
	return adjusted_x

#Draw triangle intended to be an arrow head
func draw_triangle(aimed_at : Vector2, vertical_shift: int, color : Color, is_pointing_up : bool) -> int:
	var triangle : PackedVector2Array = []
	triangle.append(aimed_at)
	triangle.append(Vector2(aimed_at.x + StyleConfig.Link.WIDTH * 2, aimed_at.y + vertical_shift * 3))
	triangle.append(Vector2(aimed_at.x - StyleConfig.Link.WIDTH * 2, aimed_at.y + vertical_shift * 3))
	draw_polygon(triangle, [color])
	return vertical_shift

#Draw link lane to which each element in a relation will connect to
func draw_link_lane(x_drawn : Array[int], x_highlight : Array[int], drawable_y_position: int):
	var most_left_x_position : int = x_drawn.min() - round(StyleConfig.Link.WIDTH / 2 - 0.5)
	var most_right_x_position : int = x_drawn.max() + round(StyleConfig.Link.WIDTH / 2 + 0.5)
	var base_color = StyleConfig.Link.HIGHLIGHT_COLOR if (highlighted_element == null) else StyleConfig.Link.DIMMED_COLOR
	draw_line_differed(Vector2(most_left_x_position, drawable_y_position), Vector2(most_right_x_position, drawable_y_position), base_color, StyleConfig.Link.WIDTH, true)
	if (not x_highlight.is_empty()):
		var most_left_highlight_x_position : int = x_highlight.min() - round(StyleConfig.Link.WIDTH / 2 - 0.5)
		var most_right_highlight_x_position : int = x_highlight.max() + round(StyleConfig.Link.WIDTH / 2 + 0.5)
		draw_line_differed(Vector2(most_left_highlight_x_position, drawable_y_position), Vector2(most_right_highlight_x_position, drawable_y_position), StyleConfig.Link.HIGHLIGHT_COLOR, StyleConfig.Link.WIDTH, true)

#Get not already drawed y 
func get_drawable_y_height(key, array_nodes: Array) -> int:
	var potential_y_position = (key.global_position.y + key.size.y + array_nodes[0].global_position.y) / 2
	return get_viable_position(potential_y_position, already_drawn_y, 1)

#Get not already drawed x
func get_drawable_x_position(potential_x : int) -> int:
	return get_viable_position(potential_x, already_drawn_x, 1)

func get_drawable_y_position_for_container_side(side : ContainerSide, key : Object, links : Array) -> int:
	match side :
		ContainerSide.ANY :
			return get_drawable_y_height(key, links)
		ContainerSide.TOP :
			return get_viable_position(get_top_side(key).y - StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, already_drawn_y, 1)
		ContainerSide.BOTTOM :
			return get_viable_position(get_bottom_side(key).y + StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, already_drawn_y, 1)
	return 0

func get_viable_position(potential : int, concerned_list : Array[int], iteration : int) -> int:
	if(potential in concerned_list):
		if (iteration % 2 == 0):
			return get_viable_position(potential - 2 * StyleConfig.Link.WIDTH * iteration, concerned_list, iteration + 1)
		else:
			return get_viable_position(potential + 2 * StyleConfig.Link.WIDTH * iteration, concerned_list, iteration + 1)
	else:
		concerned_list.append(potential)
		return potential

#With Fuseki link data draw those links
func update_link_with(fuseki_link_data, force_side_source : ContainerSide = ContainerSide.ANY):
	if(fuseki_link_data == null):
		return
	var links_as_dict : Dictionary = to_link_dictionary(fuseki_link_data)
	for key in links_as_dict.keys():
		var drawable_y_position : int = get_drawable_y_position_for_container_side(force_side_source, key, links_as_dict[key])
		var x_drawn_list : Array[int] = []
		var x_highlight_list : Array[int] = []
		var source_in_critical_path : bool = in_critical_path(key, links_as_dict[key])
		var source_color : Color = get_appropriate_link_color(source_in_critical_path)
		var source_x = draw_element_to_lane(key, drawable_y_position, source_color)
		x_drawn_list.append(source_x)
		if(source_in_critical_path):
			x_highlight_list.append(source_x)
		for association_element in links_as_dict[key]:
			var destination_in_critical_path : bool = in_critical_path(key, [association_element])
			var arrow_color : Color = get_appropriate_link_color(destination_in_critical_path)
			var drawn_x : int = draw_element_to_lane(association_element, drawable_y_position, arrow_color, true)
			x_drawn_list.append(drawn_x)
			if(destination_in_critical_path):
				x_highlight_list.append(drawn_x)
		draw_link_lane(x_drawn_list, x_highlight_list, drawable_y_position)

#Process and display -------------------------------------------------------------------------------

#Feed fuseki data
func feed_fuseki_data(feed):
	fuseki_data = feed
	on_fuseki_data_updated()
	await get_tree().create_timer(0.2).timeout
	CameraSignals.zoom_to_fit.emit(get_rect())

#Update all displayed information on data update from a signal from FusekiCallerButton
func on_fuseki_data_updated():
	if fuseki_data == null:
		return
	displayed_node_list.clear()
	update_node_with(service_container, fuseki_data.service)
	update_node_with(enabler_container, fuseki_data.enabler)
	update_node_with(model_container, fuseki_data.model)
	update_provided_things(operator_container, machine_container, fuseki_data.provided_thing)
	update_node_with(data_transmitted_container, fuseki_data.data_transmitted)
	update_node_with(sensor_container, fuseki_data.sensing_component)
	update_node_with(env_container, fuseki_data.env)
	update_node_with(sys_container, fuseki_data.sys_component)
	update_node_with(data_container, fuseki_data.data)

func _process(_delta):
	already_drawn_x.clear()
	already_drawn_y.clear()
	dimmed_lines.clear()
	highlighted_lines.clear()
	dimmed_triangles.clear()
	highlighted_triangles.clear()
	queue_redraw()

#Free all childs of a node
static func free_all_child(node : Node):
	for child in node.get_children():
		if (child.get_class() == "PanelContainer"):
			child.free()

#Draw all links
func _draw():
	if (not fuseki_data == null):
		update_link_with(fuseki_data.enabler_to_service)
		update_link_with(fuseki_data.model_to_enabler)
		update_link_with(fuseki_data.service_to_provided_thing, ContainerSide.TOP)
		update_link_with(fuseki_data.sensor_to_data_transmitted)
		update_link_with(fuseki_data.data_to_enabler)
		update_link_with(fuseki_data.data_transmitted_to_data, ContainerSide.BOTTOM)
		draw_all_differed()

# Rabbit MQ data integration ---------------------------------------------------
func _on_rabbit_data_updated(container_name: String, data : Array[String]):
	var container : GenericDisplay = get_node_by_name(container_name)
	var last_data = data[data.size() - 1]
	var is_bool : bool = last_data == "true" or last_data == "false"
	container.set_info(data, is_bool)


func _on_node_border_option_item_selected(index: int) -> void:
	border_view = index
	on_fuseki_data_updated()

func _on_node_bg_option_item_selected(index: int) -> void:
	bg_view = index
	on_fuseki_data_updated()
