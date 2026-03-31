## Manages element highlighting state for hover and click interactions.
class_name DTHighlighting

var highlighted_element: GenericDisplay = null
var all_highlighted_elements: Array[String] = []
var highlighted_with_click := false


## Handle an element hover/click event. Updates highlight state and emits signals.
func on_element_over(element_name: String, click: bool,
		get_node: Callable, link_data: DTLinkData, fuseki_data: FusekiData) -> void:
	if element_name == "":
		_clear_highlight(click)
	else:
		_apply_highlight(element_name, click, get_node, link_data, fuseki_data)


## Returns true if a link is in the highlighted "critical path".
func in_critical_path(source, destinations: Array) -> bool:
	return (highlighted_element == null
		or source == highlighted_element
		or highlighted_element in destinations)


## Returns the appropriate link color based on highlight state.
func get_link_color(is_in_critical_path: bool) -> Color:
	if is_in_critical_path:
		return StyleConfig.Link.HIGHLIGHT_COLOR
	return StyleConfig.Link.DIMMED_COLOR


# ── Private ───────────────────────────────────────────────────────────────────

func _clear_highlight(click: bool) -> void:
	if not click and highlighted_with_click:
		return
	elif click:
		highlighted_with_click = false
	highlighted_element = null
	all_highlighted_elements = []
	GenericDisplaySignals.generic_display_highlight.emit([])


func _apply_highlight(element_name: String, click: bool,
		get_node: Callable, link_data: DTLinkData, fuseki_data: FusekiData) -> void:
	if click:
		# Clicking again on a highlighted node deactivates highlights
		if element_name in all_highlighted_elements and highlighted_with_click:
			highlighted_element = null
			all_highlighted_elements = []
			GenericDisplaySignals.generic_display_highlight.emit([])
			highlighted_with_click = false
			return
		else:
			highlighted_element = get_node.call(element_name)
			all_highlighted_elements = link_data.get_all_connected_to(element_name, fuseki_data)
			GenericDisplaySignals.generic_display_highlight.emit(all_highlighted_elements)
			highlighted_with_click = true
			return

	# Mouse hover (not click) — only if nothing was click-highlighted
	if not highlighted_with_click:
		highlighted_element = get_node.call(element_name)
		all_highlighted_elements = link_data.get_all_connected_to(element_name, fuseki_data)
		GenericDisplaySignals.generic_display_highlight.emit(all_highlighted_elements)
