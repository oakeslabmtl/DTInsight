## Handles CRUD operations for DT/PT components: add, rename, delete, and
## manages the visual editing toggle (showing/hiding add-component buttons).
class_name DTVisualEditing

var visual_editing_mode := false
var _new_node_index := 1

const DEFAULT_NODE_DATA: Dictionary = {
	"type": [
		"NamedIndividual", "Component", "ContainedElement", "Thing",
		"DescribedThing", "ImplementationThing", "ConnectionComponent",
		"TimeScaleThing", "ConceptInstance"
	],
	"desc": [""]
}


## Add a new component to the given Fuseki dict and refresh the container.
func add_component(target_dict: Dictionary, container,
		displayed_node_list: Array[Node], bg_view: int, border_view: int,
		timescale_colors: Dictionary, extra_types: Array = []) -> void:
	var data = DEFAULT_NODE_DATA.duplicate_deep()
	for t in extra_types:
		data["type"].append(t)

	target_dict["new_node_" + str(_new_node_index)] = data
	_new_node_index += 1

	if container is Callable:
		container.call()
	else:
		DTNodeStyle.populate_container(container, target_dict,
			displayed_node_list, bg_view, border_view, timescale_colors)


## Edit (rename/update description) or delete a component.
## container_info: { "dict": Dictionary, "update": Callable }
func edit_node(node_name: String, container_info: Dictionary, delete: bool,
		new_name: String, new_desc: String,
		displayed_node_list: Array[Node], link_data: DTLinkData,
		fuseki_data: FusekiData) -> void:
	if container_info.is_empty():
		return

	var target_dict: Dictionary = container_info["dict"]
	var update_func: Callable = container_info["update"]

	if delete:
		_delete_component(node_name, target_dict, displayed_node_list, link_data)
	else:
		if node_name != new_name:
			_rename_component(target_dict, node_name, new_name, displayed_node_list)
			node_name = new_name
		if new_desc:
			target_dict[node_name]["desc"] = [new_desc]

	update_func.call()
	fuseki_data.build_relations()


## Toggle add-component button visibility.
func set_buttons_visible(buttons: Array, is_visible: bool) -> void:
	for btn in buttons:
		if btn:
			btn.visible = is_visible


# ── Private ───────────────────────────────────────────────────────────────────

func _delete_component(node_name: String, fuseki_dict: Dictionary,
		displayed_node_list: Array[Node], link_data: DTLinkData) -> void:
	var node = DTNodeStyle.find_node_by_name(displayed_node_list, node_name)
	if node == null:
		return
	link_data.remove_all_user_links_for(node)
	fuseki_dict.erase(node_name)
	displayed_node_list.erase(node)
	node.queue_free()


func _rename_component(fuseki_dict: Dictionary, old_name: String,
		new_name: String, displayed_node_list: Array[Node]) -> void:
	_rename_dict_key(fuseki_dict, old_name, new_name)
	var node = DTNodeStyle.find_node_by_name(displayed_node_list, old_name)
	if node:
		node.name = new_name


static func _rename_dict_key(dict: Dictionary, old_key, new_key) -> void:
	if old_key == new_key or not dict.has(old_key):
		return
	var keys = dict.keys()
	var values = dict.values()
	for i in range(keys.size()):
		if keys[i] == old_key:
			keys[i] = new_key
			break
	dict.clear()
	for i in range(keys.size()):
		dict[keys[i]] = values[i]
