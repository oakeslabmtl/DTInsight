## Handles all link drawing: deferred draw system, position math, and hit-testing.
##
## Drawing works in two phases:
##   1. draw_links() populates internal command lists (lines + triangles).
##   2. execute_draw() replays those commands on the actual CanvasItem.
class_name DTLinkRenderer

enum ContainerSide { TOP, BOTTOM, ANY }

# ── Deferred draw command lists ───────────────────────────────────────────────
var _dimmed_lines: Array[Dictionary] = []
var _highlighted_lines: Array[Dictionary] = []
var _dimmed_triangles: Array[Dictionary] = []
var _highlighted_triangles: Array[Dictionary] = []

# ── Position collision avoidance ──────────────────────────────────────────────
var _used_x: Array[int] = []
var _used_y: Array[int] = []

# ── Drawn link registry (for hit-testing) ─────────────────────────────────────
var drawn_links: Array[Dictionary] = []


## Clear all deferred draws and position caches. Call once per frame.
func clear() -> void:
	_used_x.clear()
	_used_y.clear()
	_dimmed_lines.clear()
	_highlighted_lines.clear()
	_dimmed_triangles.clear()
	_highlighted_triangles.clear()
	drawn_links.clear()


## Draw all links from a single link dictionary (source -> [destinations]).
func draw_links(links_dict: Dictionary, side: ContainerSide,
		link_type: String, highlighting: DTHighlighting) -> void:
	for source_node in links_dict:
		if source_node == null:
			continue
		var destinations = links_dict[source_node].filter(func(e): return e != null)
		if destinations.is_empty():
			continue

		var lane_y := _get_lane_y(side, source_node, destinations)
		var x_all: Array[int] = []
		var x_highlight: Array[int] = []

		# Draw source stem
		var src_in_path := highlighting.in_critical_path(source_node, destinations)
		var src_color := highlighting.get_link_color(src_in_path)
		var src_x := _draw_stem(source_node, lane_y, src_color, false)
		x_all.append(src_x)
		if src_in_path:
			x_highlight.append(src_x)

		# Draw destination stems (with arrow)
		for dest_node in destinations:
			var dest_in_path := highlighting.in_critical_path(source_node, [dest_node])
			var dest_color := highlighting.get_link_color(dest_in_path)
			var dest_x := _draw_stem(dest_node, lane_y, dest_color, true)
			x_all.append(dest_x)
			if dest_in_path:
				x_highlight.append(dest_x)
			drawn_links.append({
				"source": source_node, "destination": dest_node,
				"lane_y": lane_y, "source_x": src_x, "dest_x": dest_x,
				"type": link_type
			})

		# Draw horizontal lane connecting all stems
		_draw_lane(x_all, x_highlight, lane_y, highlighting)


## Execute all deferred draw commands on the given CanvasItem.
func execute_draw(canvas: CanvasItem) -> void:
	for line in _dimmed_lines + _highlighted_lines:
		canvas.draw_line(line.start, line.end, line.color, line.width, line.antialiased)
	for tri in _dimmed_triangles + _highlighted_triangles:
		_draw_triangle_polygon(canvas, tri.aimed_at, tri.vertical_shift, tri.color, tri.is_pointing_up)


## Draw the deletion-mode highlight for a hovered link.
func draw_deletion_highlight(canvas: CanvasItem, hovered_link: Dictionary) -> void:
	if hovered_link.is_empty():
		return
	var col := Color.RED
	var w := StyleConfig.Link.WIDTH + 2
	var ly: int = hovered_link["lane_y"]
	var sx: int = hovered_link["source_x"]
	var dx: int = hovered_link["dest_x"]
	var src_node = hovered_link["source"]
	var dest_node = hovered_link["destination"]

	canvas.draw_line(Vector2(sx, ly), Vector2(dx, ly), col, w, true)
	var src_y = _bottom(src_node).y if src_node.global_position.y < ly else _top(src_node).y
	canvas.draw_line(Vector2(sx, src_y), Vector2(sx, ly), col, w, true)
	var dest_y = _bottom(dest_node).y if dest_node.global_position.y < ly else _top(dest_node).y
	canvas.draw_line(Vector2(dx, ly), Vector2(dx, dest_y), col, w, true)

	var pointing_up = dest_node.global_position.y < ly
	var vs = StyleConfig.Link.WIDTH if pointing_up else -StyleConfig.Link.WIDTH
	_draw_triangle_polygon(canvas, Vector2(dx, dest_y), vs, col, pointing_up)


## Find a drawn link under the mouse position (for deletion mode).
func get_link_under_mouse(mouse_pos: Vector2, highlighted_element) -> Dictionary:
	const TOLERANCE = 2.0
	var links_to_check = drawn_links
	if highlighted_element != null:
		links_to_check = drawn_links.filter(
			func(l): return l["source"] == highlighted_element or l["destination"] == highlighted_element)

	for link in links_to_check:
		# Horizontal lane
		if _point_on_segment(mouse_pos, Vector2(link["source_x"], link["lane_y"]),
				Vector2(link["dest_x"], link["lane_y"]), TOLERANCE):
			return link
		# Vertical source branch
		var src_node = link["source"]
		if not src_node:
			return {}
		var src_y_start = _bottom(src_node).y if src_node.global_position.y < link["lane_y"] else _top(src_node).y
		if _point_on_segment(mouse_pos, Vector2(link["source_x"], src_y_start),
				Vector2(link["source_x"], link["lane_y"]), TOLERANCE):
			return link
		# Vertical destination branch
		var dest_node = link["destination"]
		var dest_y_end = _bottom(dest_node).y if dest_node.global_position.y < link["lane_y"] else _top(dest_node).y
		if _point_on_segment(mouse_pos, Vector2(link["dest_x"], link["lane_y"]),
				Vector2(link["dest_x"], dest_y_end), TOLERANCE):
			return link
	return {}


# ── Private: geometry helpers ─────────────────────────────────────────────────

static func _mid_x(node) -> int:
	return node.global_position.x + node.size.x / 2 - StyleConfig.Link.WIDTH / 2

static func _bottom(node) -> Vector2:
	return Vector2(_mid_x(node), node.global_position.y + node.size.y)

static func _top(node) -> Vector2:
	return Vector2(_mid_x(node), node.global_position.y)

static func _point_on_segment(pos: Vector2, start: Vector2, end: Vector2, tol: float) -> bool:
	return (pos.x >= min(start.x, end.x) - tol and pos.x <= max(start.x, end.x) + tol
		and pos.y >= min(start.y, end.y) - tol and pos.y <= max(start.y, end.y) + tol)


# ── Private: drawing primitives ───────────────────────────────────────────────

## Draw a vertical stem from a node to a horizontal lane. Adds an arrow if destination.
func _draw_stem(node, lane_y: int, color: Color, is_destination: bool) -> int:
	var pointing_up: bool = node.global_position.y < lane_y
	var edge: Vector2 = _bottom(node) if pointing_up else _top(node)
	var x: int = _unique_x(edge.x)
	var vs: int = _queue_triangle(Vector2(x, edge.y), color, pointing_up) if is_destination else 0
	_queue_line(Vector2(x, edge.y + vs), Vector2(x, lane_y), color)
	return x


func _draw_lane(x_all: Array[int], x_highlight: Array[int], lane_y: int,
		highlighting: DTHighlighting) -> void:
	var half_w = round(StyleConfig.Link.WIDTH / 2.0)
	var left: int = x_all.min() - half_w
	var right: int = x_all.max() + half_w
	var base_color = StyleConfig.Link.HIGHLIGHT_COLOR if highlighting.highlighted_element == null else StyleConfig.Link.DIMMED_COLOR
	_queue_line(Vector2(left, lane_y), Vector2(right, lane_y), base_color)
	if not x_highlight.is_empty():
		var hl: int = x_highlight.min() - half_w
		var hr: int = x_highlight.max() + half_w
		_queue_line(Vector2(hl, lane_y), Vector2(hr, lane_y), StyleConfig.Link.HIGHLIGHT_COLOR)


func _queue_line(start: Vector2, end: Vector2, color: Color) -> void:
	var entry := {"start": start, "end": end, "color": color,
		"width": StyleConfig.Link.WIDTH, "antialiased": true}
	if color == StyleConfig.Link.DIMMED_COLOR:
		_dimmed_lines.append(entry)
	else:
		_highlighted_lines.append(entry)


func _queue_triangle(aimed_at: Vector2, color: Color, is_pointing_up: bool) -> int:
	var vs = StyleConfig.Link.WIDTH if is_pointing_up else -StyleConfig.Link.WIDTH
	var entry := {"aimed_at": aimed_at, "vertical_shift": vs,
		"color": color, "is_pointing_up": is_pointing_up}
	if color == StyleConfig.Link.DIMMED_COLOR:
		_dimmed_triangles.append(entry)
	else:
		_highlighted_triangles.append(entry)
	return vs


func _draw_triangle_polygon(canvas: CanvasItem, aimed_at: Vector2,
		vertical_shift: int, color: Color, _is_pointing_up: bool) -> void:
	var w2 := StyleConfig.Link.WIDTH * 2
	var triangle := PackedVector2Array([
		aimed_at,
		Vector2(aimed_at.x + w2, aimed_at.y + vertical_shift * 3),
		Vector2(aimed_at.x - w2, aimed_at.y + vertical_shift * 3)
	])
	canvas.draw_polygon(triangle, [color])


# ── Private: position collision avoidance ─────────────────────────────────────

func _unique_x(potential: int) -> int:
	return _find_viable(potential, _used_x, 1)


func _get_lane_y(side: ContainerSide, key_node: Node, destinations: Array) -> int:
	match side:
		ContainerSide.ANY:
			var mid_y = (key_node.global_position.y + key_node.size.y + destinations[0].global_position.y) / 2
			return _find_viable(mid_y, _used_y, 1)
		ContainerSide.TOP:
			return _find_viable(_top(key_node).y - StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, _used_y, 1)
		ContainerSide.BOTTOM:
			return _find_viable(_bottom(key_node).y + StyleConfig.Link.MEAN_OUTER_LINK_DISTANCE, _used_y, 1)
	return 0


func _find_viable(potential: int, used: Array[int], iteration: int) -> int:
	if potential in used:
		var offset = 2 * StyleConfig.Link.WIDTH * iteration
		if iteration % 2 == 0:
			return _find_viable(potential - offset, used, iteration + 1)
		else:
			return _find_viable(potential + offset, used, iteration + 1)
	else:
		used.append(potential)
		return potential
