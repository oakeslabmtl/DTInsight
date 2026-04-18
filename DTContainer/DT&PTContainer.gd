extends Control

class_name DT_PT

# ── Scene-tree references ─────────────────────────────────────────────────────
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

# ── Data ──────────────────────────────────────────────────────────────────────
var fuseki_data: FusekiData = null
var displayed_node_list: Array[Node]
var timescale_colors: Dictionary = {}
var bg_view := 0
var border_view := 0
var deletion_mode := false
var hovered_link = null

# ── Helpers ───────────────────────────────────────────────────────────────────
var link_data := DTLinkData.new()
var highlighting := DTHighlighting.new()
var drag_drop := DTDragDrop.new()
var link_renderer := DTLinkRenderer.new()
var visual_editing := DTVisualEditing.new()

# ── Table-driven container mapping ────────────────────────────────────────────
# Maps each container -> its fuseki_data property name.
# operator_container and machine_container are a special case (both -> "provided_thing").
var _container_map: Dictionary = {}

# Maps container -> fuseki property for standard containers
var _fuseki_containers: Array = []


func _ready():
	# Build container mappings (must happen after @onready)
	_fuseki_containers = [
		["service", service_container],
		["enabler", enabler_container],
		["model", model_container],
		["data_transmitted", data_transmitted_container],
		["sensing_component", sensor_container],
		["env", env_container],
		["sys_component", sys_container],
		["data", data_container],
	]
	_container_map = {
		service_container: "service",
		enabler_container: "enabler",
		model_container: "model",
		data_container: "data",
		data_transmitted_container: "data_transmitted",
		sensor_container: "sensing_component",
		env_container: "env",
		sys_container: "sys_component",
	}

	# Signal connections
	GenericDisplaySignals.generic_display_over.connect(_on_element_over)
	GenericDisplaySignals.generic_display_edit.connect(_on_edit_node)
	RabbitSignals.updated_data.connect(_on_rabbit_data_updated)
	GenericDisplaySignals.start_drag.connect(_on_start_drag)
	GenericDisplaySignals.dragging.connect(_on_dragging)
	GenericDisplaySignals.stop_drag.connect(_on_stop_drag)

	# Main toolbar buttons
	for btn in get_tree().get_nodes_in_group("main_buttons"):
		if btn.name == "VisualEditingButton":
			btn.toggled.connect(_on_visual_editing_toggled)
			_on_visual_editing_toggled(btn.button_pressed)
		elif btn.name == "LinkDeletionButton":
			btn.toggled.connect(_on_link_deletion_toggled)


# ── Per-frame loop ────────────────────────────────────────────────────────────

func _process(_delta):
	link_renderer.clear()
	queue_redraw()


func _draw():
	if fuseki_data:
		var R := link_renderer
		var S := DTLinkRenderer.ContainerSide
		R.draw_links(link_data.enabler_to_service, S.ANY, "fuseki", highlighting)
		R.draw_links(link_data.model_to_enabler, S.ANY, "fuseki", highlighting)
		R.draw_links(link_data.service_to_provided_thing, S.TOP, "fuseki", highlighting)
		R.draw_links(link_data.sensor_to_data_transmitted, S.ANY, "fuseki", highlighting)
		R.draw_links(link_data.data_to_enabler, S.ANY, "fuseki", highlighting)
		R.draw_links(link_data.data_transmitted_to_data, S.BOTTOM, "fuseki", highlighting)
		R.draw_links(link_data.user_links, S.ANY, "normal", highlighting)
		R.draw_links(link_data.user_links_bot2bot, S.BOTTOM, "bot2bot", highlighting)
		R.draw_links(link_data.user_links_top2top, S.TOP, "top2top", highlighting)
		R.execute_draw(self)

	if deletion_mode and hovered_link != null and not hovered_link.is_empty():
		link_renderer.draw_deletion_highlight(self, hovered_link)


# ── Input handling ────────────────────────────────────────────────────────────

func _input(event):
	if not deletion_mode:
		return
	if event is InputEventMouseMotion:
		var mouse_pos = get_global_mouse_position()
		var link = link_renderer.get_link_under_mouse(mouse_pos, highlighting.highlighted_element)
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
				link_data.delete_link(hovered_link, fuseki_data, get_node_by_name)
				hovered_link = null
				Input.set_default_cursor_shape(Input.CURSOR_ARROW)


# ── Fuseki data flow ─────────────────────────────────────────────────────────

func set_fuseki_data(_fuseki_data: FusekiData) -> void:
	fuseki_data = _fuseki_data


func feed_fuseki_data(feed):
	fuseki_data = feed
	for node in displayed_node_list:
		if is_instance_valid(node):
			var parent = node.get_parent()
			if parent != null:
				parent.remove_child(node)
			node.queue_free()
	displayed_node_list.clear()
	on_fuseki_data_updated()
	await get_tree().create_timer(0.2).timeout
	CameraSignals.zoom_to_fit.emit(get_rect())


func on_fuseki_data_updated():
	if fuseki_data == null:
		return
	# Populate all standard containers
	for mapping in _fuseki_containers:
		DTNodeStyle.populate_container(mapping[1], fuseki_data.get(mapping[0]),
			displayed_node_list, bg_view, border_view, timescale_colors)
	# Populate special operator/machine split
	DTNodeStyle.populate_provided_things(operator_container, machine_container,
		fuseki_data.provided_thing, displayed_node_list, bg_view, border_view, timescale_colors)
	# Rebuild link dictionaries and legends
	link_data.update_from_fuseki(fuseki_data, get_node_by_name)
	_update_legends()


func get_node_by_name(node_name: String) -> GenericDisplay:
	return DTNodeStyle.find_node_by_name(displayed_node_list, node_name)


# ── Legends ───────────────────────────────────────────────────────────────────

func _update_legends():
	var timescale_keys = fuseki_data.timescales.keys()
	timescale_colors.clear()
	var s = timescale_keys.size()
	var legend_colors: Dictionary = {}
	for i in s:
		var key = timescale_keys[i]
		var color = Color.from_hsv(0.8 * float(i) / float(s - 1), 0.7, 0.9)
		timescale_colors[key] = color
		# Use description as legend label, fall back to key name
		var display_name = key
		var attrs = fuseki_data.timescales[key]
		if attrs is Dictionary and "desc" in attrs and not attrs["desc"].is_empty() and attrs["desc"][0] != "":
			display_name = attrs["desc"][0]
		legend_colors[display_name] = color
	for legend in legends:
		legend.timescales = legend_colors


# ── Signal delegates ──────────────────────────────────────────────────────────

func _on_element_over(element_name, click: bool):
	highlighting.on_element_over(element_name, click, get_node_by_name, link_data, fuseki_data)

func _on_start_drag(node):
	drag_drop.on_start_drag(node, visual_editing.visual_editing_mode, get_global_mouse_position)

func _on_dragging(node, mouse_pos):
	drag_drop.on_dragging(node, mouse_pos, displayed_node_list)

func _on_stop_drag(node):
	drag_drop.on_stop_drag(node, link_data)

func _on_rabbit_data_updated(container_name: String, data: Array[String]):
	var container: GenericDisplay = get_node_by_name(container_name)
	var last_data = data[data.size() - 1]
	container.set_info(data, last_data == "true" or last_data == "false")

func _on_node_border_option_item_selected(index: int) -> void:
	border_view = index
	on_fuseki_data_updated()

func _on_node_bg_option_item_selected(index: int) -> void:
	bg_view = index
	on_fuseki_data_updated()


# ── Visual editing delegates ──────────────────────────────────────────────────

func _on_visual_editing_toggled(toggled_on: bool) -> void:
	visual_editing.visual_editing_mode = toggled_on
	visual_editing.set_buttons_visible(_get_edit_buttons(), toggled_on)

func _on_link_deletion_toggled(toggled_on: bool) -> void:
	deletion_mode = toggled_on
	if not toggled_on:
		hovered_link = null
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	print("Link deletion mode: ", "ON" if deletion_mode else "OFF")


func _on_edit_node(node_name: String, parent_container: Node, delete: bool,
		new_node_name: String, new_node_description: String):
	var info = _resolve_container_info(parent_container)
	visual_editing.edit_node(node_name, info, delete, new_node_name,
		new_node_description, displayed_node_list, link_data, fuseki_data)


## Resolve which fuseki dict and update function to use for a given container.
func _resolve_container_info(container: Node) -> Dictionary:
	if container == operator_container or container == machine_container:
		return {
			"dict": fuseki_data.provided_thing,
			"update": func(): DTNodeStyle.populate_provided_things(
				operator_container, machine_container, fuseki_data.provided_thing,
				displayed_node_list, bg_view, border_view, timescale_colors)
		}
	if _container_map.has(container):
		var prop = _container_map[container]
		var d = fuseki_data.get(prop)
		return {
			"dict": d,
			"update": func(): DTNodeStyle.populate_container(
				container, d, displayed_node_list, bg_view, border_view, timescale_colors)
		}
	return {}


# ── Add-component button handlers (connected via .tscn signals) ───────────────

func _on_add_component_button_pressed_env():
	_add_to("env", env_container)
func _on_add_component_button_pressed_system():
	_add_to("sys_component", sys_container)
func _on_add_component_button_pressed_sensors():
	_add_to("sensing_component", sensor_container)
func _on_add_component_button_pressed_data_trans():
	_add_to("data_transmitted", data_transmitted_container)
func _on_add_component_button_pressed_services():
	_add_to("service", service_container)
func _on_add_component_button_pressed_enablers():
	_add_to("enabler", enabler_container)
func _on_add_component_button_pressed_models():
	_add_to("model", model_container)
func _on_add_component_button_pressed_data():
	_add_to("data", data_container)

func _on_add_component_button_pressed_operator():
	visual_editing.add_component(fuseki_data.provided_thing,
		func(): DTNodeStyle.populate_provided_things(operator_container, machine_container,
			fuseki_data.provided_thing, displayed_node_list, bg_view, border_view, timescale_colors),
		displayed_node_list, bg_view, border_view, timescale_colors, ["Insight"])

func _on_add_component_button_pressed_machine():
	visual_editing.add_component(fuseki_data.provided_thing,
		func(): DTNodeStyle.populate_provided_things(operator_container, machine_container,
			fuseki_data.provided_thing, displayed_node_list, bg_view, border_view, timescale_colors),
		displayed_node_list, bg_view, border_view, timescale_colors, ["Action"])


func _add_to(fuseki_prop: String, container: HBoxContainer) -> void:
	visual_editing.add_component(fuseki_data.get(fuseki_prop), container,
		displayed_node_list, bg_view, border_view, timescale_colors)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _get_edit_buttons() -> Array:
	return [
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


func _on_node_style_option_item_selected(index: int) -> void:
	for legend in legends:
		legend._on_node_style_option_item_selected(index)
