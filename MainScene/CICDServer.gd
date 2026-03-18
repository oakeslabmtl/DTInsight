## Exposes a local TCP server (default port 9090) used by CI/CD pipelines to
## trigger a full data refresh and capture pipeline:
##   1. Query the Fuseki server to reload the DT visualisation.
##   2. Dump the architecture as a YAML file.
##   3. Dump the characteristics table as an HTML file.
##   4. Capture a high-resolution screenshot by tiling viewport segments.
## Not started when running on the web platform.

extends Node

# ── Exported configuration ────────────────────────────────────────────────────
## Extra whitespace (pixels) added around the DT container when compositing
## the screenshot. x = horizontal margin, y = vertical margin.
@export var margins: Vector2 = Vector2(50, 300)

## The DT/PT container whose bounding rect defines the screenshot area.
@export var container: DT_PT

## UI nodes that should be hidden during screenshot capture so only the
## DT visualisation appears in the output image.
@export var to_hide: Array[Node] = []

# ── Server state ──────────────────────────────────────────────────────────────
var server := TCPServer.new()

@export var port: int = 9090

# ── Output paths (written to the Godot user-data directory) ───────────────────
var screenshot_save_path: String = OS.get_user_data_dir() + "/latest_screenshot.png"
var dump_architecture_save_path: String = OS.get_user_data_dir() + "/data_dump.yaml"
var dump_characteristics_table_save_path: String = OS.get_user_data_dir() + "/characteristics-table.html"


func _ready() -> void:
	# The TCP server is only used in native (non-web) builds.
	if not OS.has_feature("web"):
		start_server()


func start_server() -> void:
	if server.listen(port) == OK:
		print("CICDServer started on port ", port)
	else:
		push_error("CICDServer: Failed to listen on port " + str(port))


func _process(_delta: float) -> void:
	if server.is_connection_available():
		var client := server.take_connection()
		handle_request(client)


## Handles a single incoming TCP connection by running the full
## capture+dump pipeline and returning an HTTP 200 response.
func handle_request(client: StreamPeerTCP) -> void:
	# Trigger the Fuseki query so the visualisation reflects latest data.
	var fuseki_button = get_tree().root.get_node("MainScene/%FusekiCallerButton")
	fuseki_button._on_pressed()

	# Allow 3 seconds for the visualisation to finish loading before capturing.
	await get_tree().create_timer(3).timeout

	dump_architecture_yaml()
	dump_characteristics_table_html()
	capture_image()

	# Minimal HTTP/1.1 response — body length must match the literal string below.
	client.put_data(
		"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 33\r\n\r\nScreenshot taken and data dumped!"
		.to_utf8_buffer()
	)

	# Give the OS a moment to flush the image to disk before closing the socket.
	await get_tree().create_timer(0.2).timeout
	client.disconnect_from_host()


## Captures a full-resolution screenshot of the DT container by tiling
## viewport-sized segments and blitting them into a single image.
func capture_image() -> void:
	print("[Start Capture...]")

	# Temporarily hide UI nodes so they do not appear in the screenshot.
	for node_to_hide: Node in to_hide:
		node_to_hide.visible = false

	# Create a temporary camera fixed to the top-left of the scene.
	var camera := Camera2D.new()
	self.add_child(camera)
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.enabled = true
	camera.make_current()

	# Expand the bounding rect by the configured margins.
	var full_rect := container.get_rect()
	full_rect.position.x -= margins.x / 2
	full_rect.position.y -= margins.y / 2
	full_rect.size.x += margins.x
	full_rect.size.y += margins.y

	camera.position = full_rect.position

	# Pause the tree so the scene does not advance while we tile the screenshot.
	var tree := get_tree()
	tree.paused = true
	await tree.process_frame

	var viewport_size = get_viewport().size / camera.zoom.x
	var image := Image.create_empty(full_rect.size.x, full_rect.size.y, false, Image.FORMAT_RGBA8)

	# Sweep the camera across the full rect, capturing one viewport tile at a time.
	while camera.position.y < full_rect.size.y:
		while camera.position.x < full_rect.size.x:
			await tree.process_frame
			var segment := camera.get_viewport().get_texture().get_image()

			# Normalise the segment format before blitting.
			if segment.get_format() != Image.FORMAT_RGBA8:
				segment.convert(Image.FORMAT_RGBA8)

			var target_position := Vector2i(
				int(camera.position.x - full_rect.position.x),
				int(camera.position.y - full_rect.position.y)
			)
			var src_rect := Rect2i(Vector2i(0, 0), Vector2i(segment.get_width(), segment.get_height()))
			image.blit_rect(segment, src_rect, target_position)

			camera.position.x += viewport_size.x

		# Return to the left edge and advance one row.
		camera.position.x = full_rect.position.x
		camera.position.y += viewport_size.y

	image.save_png(screenshot_save_path)
	print("Screenshot saved at: ", screenshot_save_path)

	tree.paused = false
	camera.queue_free()

	# Restore previously hidden nodes.
	for node_to_hide: Node in to_hide:
		node_to_hide.visible = true

	print("[END Capture...]")


## Writes the architecture YAML dump to [member dump_architecture_save_path].
func dump_architecture_yaml() -> void:
	var dumper_controller = get_tree().root.get_node("MainScene/%Settings/%FusekiDumperController")
	var fuseki_data: FusekiData = get_tree().root.get_node("MainScene/FusekiData")
	dumper_controller.dump_architecture(fuseki_data, dump_architecture_save_path)


## Writes the characteristics-table HTML dump to
## [member dump_characteristics_table_save_path].
func dump_characteristics_table_html() -> void:
	var dumper_controller = get_tree().root.get_node("MainScene/%Settings/%FusekiDumperController")
	var fuseki_data: FusekiData = get_tree().root.get_node("MainScene/FusekiData")
	dumper_controller.dump_characteristics_table(fuseki_data, dump_characteristics_table_save_path)
