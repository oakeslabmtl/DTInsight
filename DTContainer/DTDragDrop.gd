## Manages drag-and-drop interactions for creating user links between nodes.
class_name DTDragDrop

var dragging_from: GenericDisplay = null
var current_hover_target: GenericDisplay = null
var drag_start_pos: Vector2
var is_dragging := false

const MIN_DRAG_DISTANCE := 5.0  # pixels before a drag is registered


## Called when a drag begins on a node.
func on_start_drag(node: GenericDisplay, visual_editing_mode: bool,
		get_mouse_pos: Callable) -> void:
	if not visual_editing_mode:
		return
	dragging_from = node
	current_hover_target = null
	is_dragging = false
	drag_start_pos = get_mouse_pos.call()


## Called each frame while dragging. Updates hover target.
func on_dragging(_node: GenericDisplay, mouse_pos: Vector2,
		displayed_node_list: Array[Node]) -> void:
	if dragging_from == null:
		return
	if not is_dragging:
		if drag_start_pos.distance_to(mouse_pos) > MIN_DRAG_DISTANCE:
			is_dragging = true
	if is_dragging:
		var hovered = _get_node_under_mouse(mouse_pos, displayed_node_list)
		if hovered != dragging_from:
			current_hover_target = hovered


## Called when a drag ends. Creates a link if valid.
func on_stop_drag(_node: GenericDisplay, link_data: DTLinkData) -> void:
	if dragging_from == null:
		return
	if not is_dragging:
		_reset()
		return
	if current_hover_target != null and current_hover_target != dragging_from:
		link_data.add_user_link(dragging_from, current_hover_target)
	_reset()


# ── Private ───────────────────────────────────────────────────────────────────

func _reset() -> void:
	dragging_from = null
	current_hover_target = null
	is_dragging = false


func _get_node_under_mouse(pos: Vector2, displayed_node_list: Array[Node]) -> GenericDisplay:
	for node in displayed_node_list:
		if node.get_global_rect().has_point(pos):
			return node
	return null
