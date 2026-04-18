## Manages link data between nodes — both Fuseki-sourced and user-created links.
class_name DTLinkData

# ── Fuseki-derived link dictionaries (source node -> [destination nodes]) ──────
var enabler_to_service: Dictionary = {}
var model_to_enabler: Dictionary = {}
var service_to_provided_thing: Dictionary = {}
var sensor_to_data_transmitted: Dictionary = {}
var data_to_enabler: Dictionary = {}
var data_transmitted_to_data: Dictionary = {}

# ── User-created link dictionaries, separated by container position ───────────
var user_links: Dictionary = {}           # cross-container links
var user_links_bot2bot: Dictionary = {}   # bottom-to-bottom container links
var user_links_top2top: Dictionary = {}   # top-to-top container links

# Container classification for determining link routing
const TOP_CONTAINERS := ["ServicesContainer", "MachineContainer", "OperatorContainer"]
const BOT_CONTAINERS := [
	"DataTransmittedContainer", "ModelsContainer", "DataContainer",
	"SystemContainer", "EnvContainer"
]


## Add a user-created link, automatically categorizing by container position.
func add_user_link(src: GenericDisplay, dest: GenericDisplay) -> void:
	var src_parent = src.get_parent().name
	var dest_parent = dest.get_parent().name

	var target_dict: Dictionary
	if src_parent in BOT_CONTAINERS and dest_parent in BOT_CONTAINERS:
		target_dict = user_links_bot2bot
	elif src_parent in TOP_CONTAINERS and dest_parent in TOP_CONTAINERS:
		target_dict = user_links_top2top
	else:
		target_dict = user_links

	if not target_dict.has(src):
		target_dict[src] = []
	target_dict[src].append(dest)


## Rebuild all Fuseki link dictionaries from current FusekiData.
func update_from_fuseki(fuseki_data: FusekiData, get_node: Callable) -> void:
	enabler_to_service.clear()
	model_to_enabler.clear()
	service_to_provided_thing.clear()
	sensor_to_data_transmitted.clear()
	data_to_enabler.clear()
	data_transmitted_to_data.clear()
	_build_link_dict(enabler_to_service, fuseki_data.enabler_to_service, get_node)
	_build_link_dict(model_to_enabler, fuseki_data.model_to_enabler, get_node)
	_build_link_dict(service_to_provided_thing, fuseki_data.service_to_provided_thing, get_node)
	_build_link_dict(sensor_to_data_transmitted, fuseki_data.sensor_to_data_transmitted, get_node)
	_build_link_dict(data_to_enabler, fuseki_data.data_to_enabler, get_node)
	_build_link_dict(data_transmitted_to_data, fuseki_data.data_transmitted_to_data, get_node)


## Delete a link (user or Fuseki) based on link info from the renderer.
func delete_link(link_info: Dictionary, fuseki_data: FusekiData, get_node: Callable) -> void:
	if link_info.is_empty():
		return
	var source = link_info["source"]
	var dest = link_info["destination"]
	var link_type = link_info["type"]

	if link_type == "fuseki":
		_delete_fuseki_link(source, dest, fuseki_data, get_node)
		return

	# Delete a user link
	var target_dict = null
	match link_type:
		"normal": target_dict = user_links
		"bot2bot": target_dict = user_links_bot2bot
		"top2top": target_dict = user_links_top2top

	if target_dict != null and target_dict.has(source):
		target_dict[source].erase(dest)
		if target_dict[source].is_empty():
			target_dict.erase(source)
		print("User link deleted: ", source.name, " -> ", dest.name)


## Remove all user links involving a specific node (for component deletion).
func remove_all_user_links_for(node: GenericDisplay) -> void:
	for link_dict in [user_links, user_links_bot2bot, user_links_top2top]:
		_remove_node_from_dict(node, link_dict)


## Returns all element names connected to the given element through any link.
func get_all_connected_to(element_name: String, fuseki_data: FusekiData) -> Array[String]:
	var connected: Array[String] = [element_name]

	# Gather all links (fuseki + user)
	var all_links = []
	all_links += fuseki_data.enabler_to_service
	all_links += fuseki_data.model_to_enabler
	all_links += fuseki_data.service_to_provided_thing
	all_links += fuseki_data.sensor_to_data_transmitted
	all_links += fuseki_data.data_transmitted_to_data
	all_links += fuseki_data.data_to_enabler

	for dict in [user_links, user_links_top2top, user_links_bot2bot]:
		for src in dict:
			for dst in dict[src]:
				all_links.append({"source": src.name, "destination": dst.name})

	for link in all_links:
		var source_name := ""
		var dest_name := ""
		if typeof(link) == TYPE_DICTIONARY:
			source_name = link["source"]
			dest_name = link["destination"]
		else:
			source_name = link.source
			dest_name = link.destination
		if source_name == element_name:
			connected.append(dest_name)
		if dest_name == element_name:
			connected.append(source_name)
	return connected


# ── Private helpers ───────────────────────────────────────────────────────────

func _build_link_dict(links: Dictionary, fuseki_link_data, get_node: Callable) -> void:
	for link in fuseki_link_data:
		var source_node = get_node.call(link.source)
		if source_node == null:
			continue
		var destination_node = get_node.call(link.destination)
		if destination_node == null:
			continue
		if not links.has(source_node):
			links[source_node] = []
		links[source_node].append(destination_node)


func _delete_fuseki_link(source: GenericDisplay, dest: GenericDisplay,
		fuseki_data: FusekiData, get_node: Callable) -> void:
	if fuseki_data == null:
		return
	var source_name = source.name
	var dest_name = dest.name
	var link_arrays = [
		fuseki_data.enabler_to_service, fuseki_data.model_to_enabler,
		fuseki_data.service_to_provided_thing, fuseki_data.sensor_to_data_transmitted,
		fuseki_data.data_transmitted_to_data, fuseki_data.data_to_enabler
	]
	for link_array in link_arrays:
		for i in range(link_array.size() - 1, -1, -1):
			var link = link_array[i]
			if link.source == source_name and link.destination == dest_name:
				link_array.remove_at(i)
				print("Fuseki link deleted: ", source_name, " -> ", dest_name)
				update_from_fuseki(fuseki_data, get_node)
				return


func _remove_node_from_dict(node: GenericDisplay, link_dict: Dictionary) -> void:
	if link_dict.has(node):
		link_dict.erase(node)
	for src in link_dict.keys():
		link_dict[src].erase(node)
		if link_dict[src].is_empty():
			link_dict.erase(src)
