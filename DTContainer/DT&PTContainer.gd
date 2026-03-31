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
@onready var legends = [%Legends1, %Legends2]

#Access to fuseki data
var fuseki_data : FusekiData = null

var links_as_dict_enabler_to_service : Dictionary = {}
var links_as_dict_model_to_enabler : Dictionary = {}
var links_as_dict_service_to_provided_thing : Dictionary = {}
var links_as_dict_sensor_to_data_transmitted : Dictionary = {}
var links_as_dict_data_to_enabler : Dictionary = {}
var links_as_dict_data_transmitted_to_data : Dictionary = {}

var timescale_colors: Dictionary


#Load the generic display scene
const GenericDisplay = preload("res://GenericDisplay/generic_display.tscn")

#name of highlighted element
var highlighted_element = null
var all_highlighted_element = []
var highlighted_with_click = false

var deletion_mode = false
var hovered_link = null
var visual_editing_mode = false

# Border and background views
var bg_view = 0
var border_view = 0

#initialization
func _ready():
	GenericDisplaySignals.generic_display_over.connect(_on_element_over)
	GenericDisplaySignals.generic_display_edit.connect(edit_node)
	RabbitSignals.updated_data.connect(_on_rabbit_data_updated)

	GenericDisplaySignals.start_drag.connect(_on_start_drag)
	GenericDisplaySignals.dragging.connect(_on_dragging)
	GenericDisplaySignals.stop_drag.connect(_on_stop_drag)
	
	var buttons = get_tree().get_nodes_in_group("main_buttons")
	for btn in buttons:
		if btn.name == "VisualEditingButton":
			btn.toggled.connect(_on_visual_editing_toggled)
			_on_visual_editing_toggled(btn.button_pressed)
		elif btn.name == "LinkDeletionButton":
			btn.toggled.connect(_on_link_deletion_toggled)

func _input(event):
	if not deletion_mode:
		return	
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var link = get_link_under_mouse(mouse_pos)		
		if not link.is_empty():
			hovered_link = link
			if link["type"] == "fuseki":
				Input.set_default_cursor_shape(Input.CURSOR_FORBIDDEN) 
			else:
				Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
		else:
			hovered_link = null
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)	
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if hovered_link != null:
				if hovered_link["type"] == "fuseki":
					print("Warning: Deleting a Fuseki link (from data source)")
				delete_link(hovered_link)
				hovered_link = null
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func set_fuseki_data(_fuseki_data: FusekiData) -> void:
	fuseki_data = _fuseki_data

#Node and element manipulation functions -----------------------------------------------------------

# Drag and drop functions
var dragging_from : GenericDisplay = null
var current_hover_target : GenericDisplay = null
var drag_start_pos : Vector2
var is_dragging := false
const MIN_DRAG_DISTANCE := 5.0   # pixels, arbitrarily chosen

func get_node_under_mouse(pos : Vector2) -> GenericDisplay:
	for node in displayed_node_list:
		if node.get_global_rect().has_point(pos):
			return node
	return null

func _is_point_on_segment(pos: Vector2, start: Vector2, end: Vector2, tolerance: float) -> bool:
	var min_x = min(start.x, end.x) - tolerance
	var max_x = max(start.x, end.x) + tolerance
	var min_y = min(start.y, end.y) - tolerance
	var max_y = max(start.y, end.y) + tolerance
	return pos.x >= min_x and pos.x <= max_x and pos.y >= min_y and pos.y <= max_y

func get_link_under_mouse(mouse_pos: Vector2) -> Dictionary:
	const CLICK_TOLERANCE = 2.0  # tolerance pixels for clicking on a link
	var links_to_check = drawn_links
	if highlighted_element != null:
		links_to_check = drawn_links.filter(func(l): return l["source"] == highlighted_element or l["destination"] == highlighted_element)
	
	for link in links_to_check:
		# Horizontal lane
		if _is_point_on_segment(mouse_pos, Vector2(link["source_x"], link["lane_y"]), Vector2(link["dest_x"], link["lane_y"]), CLICK_TOLERANCE):
			return link
		
		# Vertical source branch
		var src_node = link["source"]
		var src_y_start = get_bottom_side(src_node).y if src_node.global_position.y < link["lane_y"] else get_top_side(src_node).y
		if _is_point_on_segment(mouse_pos, Vector2(link["source_x"], src_y_start), Vector2(link["source_x"], link["lane_y"]), CLICK_TOLERANCE):
			return link
		
		# Vertical dest branch
		var dest_node = link["destination"]
		var dest_y_end = get_bottom_side(dest_node).y if dest_node.global_position.y < link["lane_y"] else get_top_side(dest_node).y
		if _is_point_on_segment(mouse_pos, Vector2(link["dest_x"], link["lane_y"]), Vector2(link["dest_x"], dest_y_end), CLICK_TOLERANCE):
			return link
			
	return {}

func _on_start_drag(node):
	if not visual_editing_mode:
		return
	dragging_from = node
	current_hover_target = null
	is_dragging = false
	drag_start_pos = get_global_mouse_position()

func _on_dragging(node, mouse_pos):
	if dragging_from == null:
		return
	if not is_dragging:
		if drag_start_pos.distance_to(mouse_pos) > MIN_DRAG_DISTANCE:
			is_dragging = true
	if is_dragging:	
		var hovered = get_node_under_mouse(mouse_pos)
		if hovered != dragging_from:
			current_hover_target = hovered

func _on_stop_drag(node):
	if dragging_from == null:
		return	
	if not is_dragging:
		dragging_from = null
		current_hover_target = null
		return
	if current_hover_target != null and current_hover_target != dragging_from:
		_add_user_link(dragging_from, current_hover_target)
	# reset
	dragging_from = null
	current_hover_target = null
	is_dragging = false

#Array of displayes nodes
var displayed_node_list: Array[Node]
var link_dict: Dictionary

#Attributes
const timescale_key : String = "hasTimeScale"
const implementation_key : String = "hasImplementation"
const type_attribute : String = "type"

#Operator/machine
const operator_type : String = "Insight"

#Set the starting start of a node when loaded
func set_starting_node_style(generic_node : GenericDisplay, attributes : Dictionary):
	# Structural style
	if (PythonConfig.LOCATION_KEY in attributes.keys()):
		generic_node.set_python_script_location(attributes[PythonConfig.LOCATION_KEY][0])
	if ("HasVisualization" in attributes.keys() and attributes["HasVisualization"][0] == "true"):
		generic_node.set_visualization()
	if ("desc" in attributes.keys() and attributes["desc"][0] != ""):
		generic_node.set_description(attributes["desc"][0])
	else:
		generic_node.set_description("")
	# Visual style
	generic_node.set_default_style()
	generic_node.set_node_style(StyleConfig.DTElement.DIMMED_COLOR, true, false)
	generic_node.set_node_style(StyleConfig.DTElement.BORDER_COLOR, false, true)
	if (implementation_key in attributes.keys()):
		var is_border = border_view == 2
		var is_bg = bg_view == 2
		match attributes[implementation_key]:
			["planned"]:
				generic_node.set_node_style(StyleConfig.Implementation.PLANNED, is_bg, is_border)
			["active"]:
				generic_node.set_node_style(StyleConfig.Implementation.ACTIVE, is_bg, is_border)
			["implemented"]:
				generic_node.set_node_style(StyleConfig.Implementation.IMPLEMENTED, is_bg, is_border)
	elif (timescale_key in attributes.keys()):
		var is_border = border_view == 3
		var is_bg = bg_view == 3
		var attr = attributes[timescale_key][0]
		if attr in timescale_colors:
			generic_node.set_node_style(timescale_colors[attr], is_bg, is_border)

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
		if (displayed_node.name == node_name && displayed_node != null):
			return displayed_node
	#print(node_name + " not found in :")
	#print(displayed_node_list)
	return null

#Get a list of elements connected to inputed element
func get_all_connected_to(element_name : String) -> Array[String]:
	var all_connected : Array[String]= [element_name]
	var all_links = []
	all_links += fuseki_data.enabler_to_service + fuseki_data.model_to_enabler + fuseki_data.service_to_provided_thing + fuseki_data.sensor_to_data_transmitted + fuseki_data.data_transmitted_to_data + fuseki_data.data_to_enabler
	for src in user_links.keys():
		for dst in user_links[src]:
			all_links.append({"source": src.name, "destination": dst.name})
	for src in user_links_top2top.keys():
		for dst in user_links_top2top[src]:
			all_links.append({"source": src.name, "destination": dst.name})
	for src in user_links_bot2bot.keys():
		for dst in user_links_bot2bot[src]:
			all_links.append({"source": src.name, "destination": dst.name})
	for link in all_links:
		var source_name := ""
		var dest_name := ""
		if typeof(link) == TYPE_DICTIONARY: 
			source_name = link["source"]
			dest_name = link["destination"]
		else :
			source_name = link.source
			dest_name = link.destination
		if source_name == element_name:
			all_connected.append(link.destination)
		if dest_name == element_name:
			all_connected.append(link.source)
	return all_connected

#Return middle position of a node on the x axis
static func get_middle_x(node) -> int:
	var node_position = node.global_position
	var node_size = node.size
	return node_position.x + node_size.x / 2 - StyleConfig.Link.WIDTH / 2

#Return middle bottom position of a node
func get_bottom_side(node: Node) -> Vector2:
	var node_position = node.global_position
	var node_size = node.size
	var corrected_position = Vector2(DT_PT.get_middle_x(node), node_position.y + node_size.y)
	return corrected_position

#Return middle top position of a node
func get_top_side(node: Node) -> Vector2:
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

var drawn_links : Array[Dictionary] = []

# 3 dictionary with (source node -> [destination node, ...])
# Differencing the bot and top containers for formatting the arrows correctly
var user_links : Dictionary = {}
var user_links_bot2bot : Dictionary = {}
var user_links_top2top : Dictionary = {}

# 2 list for top and bottom containers, for formatting the arrows correctly
var top_container := [
	"ServicesContainer",
	"MachineContainer",
	"OperatorContainer"
]
var bot_container := [
	"DataTransmittedContainer",
	"ModelsContainer",
	"DataContainer",
	"SystemContainer",
	"EnvContainer"
]

# Add link a user-drawn link
func _add_user_link(src: GenericDisplay, dest: GenericDisplay):
	if src.get_parent().name in bot_container and dest.get_parent().name in bot_container:
		if not user_links_bot2bot.has(src):
			user_links_bot2bot[src] = []
		user_links_bot2bot[src].append(dest)
	elif src.get_parent().name in top_container and dest.get_parent().name in top_container:
		if not user_links_top2top.has(src):
			user_links_top2top[src] = []
		user_links_top2top[src].append(dest)
	else:
		if not user_links.has(src):
			user_links[src] = []
		user_links[src].append(dest)

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

func register_drawn_link(source_node: GenericDisplay, dest_node: GenericDisplay, lane_y: int, source_x: int, dest_x: int, link_dict_type: String):
	drawn_links.append({
		"source": source_node,
		"destination": dest_node,
		"lane_y": lane_y,
		"source_x": source_x,
		"dest_x": dest_x,
		"type": link_dict_type  # "normal", "bot2bot", "top2top", "fuseki"
	})

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

# Update a node with Fuseki element data by creating a generic display node
func update_node_with(visual_container : HBoxContainer, fuseki_node_data : Dictionary):
	#DT_PT.free_all_child(visual_container)
	for key in fuseki_node_data.keys():
		var dt_component = get_node_by_name(key)
		if dt_component == null:
			var new_node : GenericDisplay = GenericDisplay.instantiate()
			new_node.name = key
			new_node.set_text(key)
			visual_container.add_child(new_node)
			displayed_node_list.append(new_node)
			set_starting_node_style(new_node, fuseki_node_data[key])
		else:
			set_starting_node_style(dt_component, fuseki_node_data[key])

#Transform fuseki link data to a dictionary (source node -> destination node)
func to_link_dictionary(links, fuseki_link_data):
	for link in fuseki_link_data:
		var source_node = get_node_by_name(link.source)
		if source_node == null:
			return {}
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
func draw_element_to_lane(node, drawable_y_position : int, color : Color, destination : bool = false):
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
func get_drawable_y_height(key_node: Node, array_nodes: Array) -> int:
	var potential_y_position = (key_node.global_position.y + key_node.size.y + array_nodes[0].global_position.y) / 2
	return get_viable_position(potential_y_position, already_drawn_y, 1)

#Get not already drawed x
func get_drawable_x_position(potential_x : int) -> int:
	return get_viable_position(potential_x, already_drawn_x, 1)

func get_drawable_y_position_for_container_side(side : ContainerSide, key_node : Node, links : Array) -> int:
	match side :
		ContainerSide.ANY :
			return get_drawable_y_height(key_node, links)
		ContainerSide.TOP :
			return get_viable_position(get_top_side(key_node).y - StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, already_drawn_y, 1)
		ContainerSide.BOTTOM :
			return get_viable_position(get_bottom_side(key_node).y + StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, already_drawn_y, 1)
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
func update_link_with(links_as_dict: Dictionary, force_side_source : ContainerSide = ContainerSide.ANY, link_type: String = "fuseki"):
	for key_node in links_as_dict.keys():
		if key_node == null:
			continue
		# Remove null values from the array
		links_as_dict[key_node] = links_as_dict[key_node].filter(func(e): return e != null)
		if links_as_dict[key_node].is_empty():
			continue
		var drawable_y_position : int = get_drawable_y_position_for_container_side(force_side_source, key_node, links_as_dict[key_node])
		var x_drawn_list : Array[int] = []
		var x_highlight_list : Array[int] = []
		var source_in_critical_path : bool = in_critical_path(key_node, links_as_dict[key_node])
		var source_color : Color = get_appropriate_link_color(source_in_critical_path)
		var source_x = draw_element_to_lane(key_node, drawable_y_position, source_color)
		x_drawn_list.append(source_x)
		if(source_in_critical_path):
			x_highlight_list.append(source_x)
		for association_element in links_as_dict[key_node]:
			var destination_in_critical_path : bool = in_critical_path(key_node, [association_element])
			var arrow_color : Color = get_appropriate_link_color(destination_in_critical_path)
			var drawn_x : int = draw_element_to_lane(association_element, drawable_y_position, arrow_color, true)
			x_drawn_list.append(drawn_x)
			if(destination_in_critical_path):
				x_highlight_list.append(drawn_x)
			register_drawn_link(key_node, association_element, drawable_y_position, source_x, drawn_x, link_type)
		draw_link_lane(x_drawn_list, x_highlight_list, drawable_y_position)

func delete_link(link_info: Dictionary):
	if link_info.is_empty():
		return
	
	var source = link_info["source"]
	var dest = link_info["destination"]
	var link_type = link_info["type"]
	
	# Delete a Fuseki link
	if link_type == "fuseki":
		delete_fuseki_link(source, dest)
		return
	
	# Delete a user link
	var target_dict = null
	match link_type:
		"normal":
			target_dict = user_links
		"bot2bot":
			target_dict = user_links_bot2bot
		"top2top":
			target_dict = user_links_top2top
	
	if target_dict != null and target_dict.has(source):
		target_dict[source].erase(dest)
		if target_dict[source].is_empty():
			target_dict.erase(source)
		print("User link deleted: ", source.name, " -> ", dest.name)

func delete_fuseki_link(source: GenericDisplay, dest: GenericDisplay):
	if fuseki_data == null:
		return
	
	var source_name = source.name
	var dest_name = dest.name
	
	var link_arrays = [
		fuseki_data.enabler_to_service,
		fuseki_data.model_to_enabler,
		fuseki_data.service_to_provided_thing,
		fuseki_data.sensor_to_data_transmitted,
		fuseki_data.data_transmitted_to_data,
		fuseki_data.data_to_enabler
	]
	
	var link_found = false
	for link_array in link_arrays:
		for i in range(link_array.size() - 1, -1, -1):
			var link = link_array[i]
			if link.source == source_name and link.destination == dest_name:
				link_array.remove_at(i)
				link_found = true
				print("Fuseki link deleted: ", source_name, " -> ", dest_name)
				break
		if link_found:
			break
	
	if link_found:
		update_link_dicts()

#Process and display -------------------------------------------------------------------------------

#Feed fuseki data
func feed_fuseki_data(feed):
	fuseki_data = feed
	for displayed_node in displayed_node_list:
		displayed_node.get_parent().remove_child(displayed_node)
	displayed_node_list.clear()
	on_fuseki_data_updated()
	await get_tree().create_timer(0.2).timeout
	CameraSignals.zoom_to_fit.emit(get_rect())

#Update all displayed information on data update from a signal from FusekiCallerButton
func on_fuseki_data_updated():
	if fuseki_data == null:
		return
	update_node_with(service_container, fuseki_data.service)
	update_node_with(enabler_container, fuseki_data.enabler)
	update_node_with(model_container, fuseki_data.model)
	update_provided_things(operator_container, machine_container, fuseki_data.provided_thing)
	update_node_with(data_transmitted_container, fuseki_data.data_transmitted)
	update_node_with(sensor_container, fuseki_data.sensing_component)
	update_node_with(env_container, fuseki_data.env)
	update_node_with(sys_container, fuseki_data.sys_component)
	update_node_with(data_container, fuseki_data.data)
	
	update_link_dicts()

	update_legends()

func update_link_dicts():
	links_as_dict_enabler_to_service.clear()
	links_as_dict_model_to_enabler.clear()
	links_as_dict_service_to_provided_thing.clear()
	links_as_dict_sensor_to_data_transmitted.clear()
	links_as_dict_data_to_enabler.clear()
	links_as_dict_data_transmitted_to_data.clear()
	to_link_dictionary(links_as_dict_enabler_to_service, fuseki_data.enabler_to_service)
	to_link_dictionary(links_as_dict_model_to_enabler, fuseki_data.model_to_enabler)
	to_link_dictionary(links_as_dict_service_to_provided_thing, fuseki_data.service_to_provided_thing)
	to_link_dictionary(links_as_dict_sensor_to_data_transmitted, fuseki_data.sensor_to_data_transmitted)
	to_link_dictionary(links_as_dict_data_to_enabler, fuseki_data.data_to_enabler)
	to_link_dictionary(links_as_dict_data_transmitted_to_data, fuseki_data.data_transmitted_to_data)

func update_legends():
	var timescales = fuseki_data.timescales.keys()
	timescale_colors.clear()
	var s = timescales.size();
	for timescale_index in s:
		timescale_colors[timescales[timescale_index]] = Color.from_hsv(0.8 * float(timescale_index) / float(s - 1), 0.7, 0.9)
	
	for legend in legends:
		legend.timescales = timescale_colors

func _process(_delta):
	already_drawn_x.clear()
	already_drawn_y.clear()
	dimmed_lines.clear()
	highlighted_lines.clear()
	dimmed_triangles.clear()
	highlighted_triangles.clear()
	drawn_links.clear()
	queue_redraw()

#Free all childs of a node
static func free_all_child(node : Node):
	for child in node.get_children():
		if (child.get_class() == "PanelContainer"):
			child.queue_free()

#Draw all links
func _draw():
	if (fuseki_data):
		update_link_with(links_as_dict_enabler_to_service, ContainerSide.ANY, "fuseki")
		update_link_with(links_as_dict_model_to_enabler, ContainerSide.ANY, "fuseki")
		update_link_with(links_as_dict_service_to_provided_thing, ContainerSide.TOP, "fuseki")
		update_link_with(links_as_dict_sensor_to_data_transmitted, ContainerSide.ANY, "fuseki")
		update_link_with(links_as_dict_data_to_enabler, ContainerSide.ANY, "fuseki")
		update_link_with(links_as_dict_data_transmitted_to_data, ContainerSide.BOTTOM, "fuseki")
		update_link_with(user_links, ContainerSide.ANY, "normal")
		update_link_with(user_links_bot2bot, ContainerSide.BOTTOM, "bot2bot")
		update_link_with(user_links_top2top, ContainerSide.TOP, "top2top")
		draw_all_differed()

	if deletion_mode and hovered_link != null and not hovered_link.is_empty():
		var col = Color.RED
		var width = StyleConfig.Link.WIDTH + 2
		var ly = hovered_link["lane_y"]
		var sx = hovered_link["source_x"]
		var dx = hovered_link["dest_x"]
		var src_node = hovered_link["source"]
		var dest_node = hovered_link["destination"]
		draw_line(Vector2(sx, ly), Vector2(dx, ly), col, width, true)
		var src_y_edge = get_bottom_side(src_node).y if src_node.global_position.y < ly else get_top_side(src_node).y
		draw_line(Vector2(sx, src_y_edge), Vector2(sx, ly), col, width, true)
		var dest_y_edge = get_bottom_side(dest_node).y if dest_node.global_position.y < ly else get_top_side(dest_node).y
		draw_line(Vector2(dx, ly), Vector2(dx, dest_y_edge), col, width, true)
		var is_pointing_up = dest_node.global_position.y < ly
		var vertical_shift = StyleConfig.Link.WIDTH if is_pointing_up else - StyleConfig.Link.WIDTH
		draw_triangle(Vector2(dx, dest_y_edge), vertical_shift, col, is_pointing_up)

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

## Adding nodes to containers

var new_node_index = 1
var default_fuseki_node_data : Dictionary = { "type": ["NamedIndividual", "Component", "ContainedElement", "Thing", "DescribedThing", "ImplementationThing", "ConnectionComponent", "TimeScaleThing", "ConceptInstance"], "desc": [""] }

func _add_component(target_dict: Dictionary, container, extra_types: Array = []) -> void:
	var new_fuseki_node_data = default_fuseki_node_data.duplicate_deep()
	for type in extra_types:
		new_fuseki_node_data["type"].append(type)
	
	target_dict["new_node_" + str(new_node_index)] = new_fuseki_node_data
	new_node_index += 1
	
	if container is Callable:
		container.call()
	else:
		update_node_with(container, target_dict)

func _on_add_component_button_pressed_env(): _add_component(fuseki_data.env, env_container)
func _on_add_component_button_pressed_system(): _add_component(fuseki_data.sys_component, sys_container)
func _on_add_component_button_pressed_operator(): _add_component(fuseki_data.provided_thing, func(): update_provided_things(operator_container, machine_container, fuseki_data.provided_thing), ["Insight"])
func _on_add_component_button_pressed_machine(): _add_component(fuseki_data.provided_thing, func(): update_provided_things(operator_container, machine_container, fuseki_data.provided_thing), ["Action"])
func _on_add_component_button_pressed_sensors(): _add_component(fuseki_data.sensing_component, sensor_container)
func _on_add_component_button_pressed_data_trans(): _add_component(fuseki_data.data_transmitted, data_transmitted_container)
func _on_add_component_button_pressed_services(): _add_component(fuseki_data.service, service_container)
func _on_add_component_button_pressed_enablers(): _add_component(fuseki_data.enabler, enabler_container)
func _on_add_component_button_pressed_models(): _add_component(fuseki_data.model, model_container)
func _on_add_component_button_pressed_data(): _add_component(fuseki_data.data, data_container)

## Visual editing

func _on_visual_editing_toggled(toggled_on: bool) -> void:
	visual_editing_mode = toggled_on
	if toggled_on:
		enable_visual_editing()
	else:
		disable_visual_editing()

func _on_link_deletion_toggled(toggled_on: bool) -> void:
	deletion_mode = toggled_on
	if not toggled_on:
		hovered_link = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("Link deletion mode: ", "ON" if deletion_mode else "OFF")

func _set_visual_editing_buttons_visible(is_visible: bool):
	var buttons = [
		$DTContainer/EnablersPanel/AddComponentButton,
		$DTContainer/ServicesPanel/AddComponentButton,
		$DTContainer/ModelsDataPanel/AddComponentButton,
		$PTContainer/DataTravelContainer/DataOutPanel/AddComponentButton,
		$PTContainer/DataTravelContainer/MachinePanel/AddComponentButton,
		$"PTContainer/Operator&EnvContainer/OperatorPanel/AddComponentButton",
		$"PTContainer/Operator&EnvContainer/ExperimentContainer/EnvPanel/AddComponentButton",
		$"PTContainer/Operator&EnvContainer/ExperimentContainer/SystemPanel/AddComponentButton",
		$DTContainer/ModelsDataPanel/ModelsDataContainer/ModelsPanelContainer/AddComponentButton,
		$PTContainer/DataTravelContainer/DataOutPanel/DataOutContainer/HBoxContainer/AddComponentButton
	]
	for btn in buttons:
		if btn: btn.visible = is_visible

func enable_visual_editing(): _set_visual_editing_buttons_visible(true)
func disable_visual_editing(): _set_visual_editing_buttons_visible(false)

func rename_dict_key(dict: Dictionary, old_key, new_key) -> void:
	if old_key == new_key or not dict.has(old_key):
		return  # nothing to do
	var keys = dict.keys()
	var values = dict.values()
	for i in range(keys.size()):
		if keys[i] == old_key:
			keys[i] = new_key
			break
	dict.clear()
	for i in range(keys.size()):
		dict[keys[i]] = values[i]

func _remove_node_from_link_dict(node: GenericDisplay, link_dict: Dictionary) -> void:
	if link_dict.has(node):
		link_dict.erase(node)
	for src in link_dict.keys():
		link_dict[src].erase(node)
		if link_dict[src].is_empty():
			link_dict.erase(src)

func remove_all_user_links_for(node: GenericDisplay) -> void:
	_remove_node_from_link_dict(node, user_links)
	_remove_node_from_link_dict(node, user_links_bot2bot)
	_remove_node_from_link_dict(node, user_links_top2top)


func delete_component(node_name, fuseki_dict, parent_container: Node):
	var node = get_node_by_name(node_name)
	remove_all_user_links_for(node)
	fuseki_dict.erase(node_name)
	get_node_by_name(node_name).queue_free()
	displayed_node_list.erase(get_node_by_name(node_name))

func rename_component(fuseki_dict, node_name, new_node_name):
	rename_dict_key(fuseki_dict, node_name, new_node_name)
	get_node_by_name(node_name).name = new_node_name
	
# Edit the FusekiData of a specific node
func edit_node(node_name: String, parent_container: Node, delete: bool, new_node_name: String, new_node_description: String):
	var target_dict = null
	var update_func = null
	
	if parent_container == service_container:
		target_dict = fuseki_data.service
		update_func = func(): update_node_with(service_container, target_dict)
	elif parent_container == enabler_container:
		target_dict = fuseki_data.enabler
		update_func = func(): update_node_with(enabler_container, target_dict)
	elif parent_container == model_container:
		target_dict = fuseki_data.model
		update_func = func(): update_node_with(model_container, target_dict)
	elif parent_container == data_container:
		target_dict = fuseki_data.data
		update_func = func(): update_node_with(data_container, target_dict)
	elif parent_container == data_transmitted_container:
		target_dict = fuseki_data.data_transmitted
		update_func = func(): update_node_with(data_transmitted_container, target_dict)
	elif parent_container == sensor_container:
		target_dict = fuseki_data.sensing_component
		update_func = func(): update_node_with(sensor_container, target_dict)
	elif parent_container == env_container:
		target_dict = fuseki_data.env
		update_func = func(): update_node_with(env_container, target_dict)
	elif parent_container == sys_container:
		target_dict = fuseki_data.sys_component
		update_func = func(): update_node_with(sys_container, target_dict)
	elif parent_container == operator_container or parent_container == machine_container:
		target_dict = fuseki_data.provided_thing
		update_func = func(): update_provided_things(operator_container, machine_container, target_dict)
	
	if target_dict != null and update_func != null:
		if delete:
			delete_component(node_name, target_dict, parent_container)
		else:
			if node_name != new_node_name:
				rename_component(target_dict, node_name, new_node_name)
				node_name = new_node_name
			if new_node_description:
				target_dict[node_name]["desc"] = [new_node_description]
		update_func.call()

	fuseki_data.build_relations()
