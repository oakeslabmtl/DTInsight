## Root controller for the Main Scene. Wires together the core subsystems
## (Fuseki caller, data manager, DT container, and Fuseki dumper) and handles
## the platform-specific start-up path:
##   - Native builds: RabbitMQ is connected for live data streaming.
##   - Web builds:    The control panel is hidden and YAML data is polled from
##                    the embedding page via JavaScriptBridge.

extends Node

# ── Scene references ──────────────────────────────────────────────────────────
@onready var fuseki_caller = %FusekiCallerButton
@onready var fuseki_dumper = $ControlLayer/SettingsBackground/Settings/%FusekiDumperController
@onready var fuseki_data: FusekiData = $FusekiData
@onready var dt_container: BoxContainer = $DTContainer


func _ready() -> void:
	# Inject the shared FusekiData manager into every subsystem that needs it.
	fuseki_caller.set_fuseki_data_manager(fuseki_data)
	fuseki_dumper.set_fuseki_data_manager(fuseki_data)
	dt_container.set_fuseki_data(fuseki_data)

	# React to Fuseki data updates to refresh the visualisation.
	FusekiSignals.fuseki_data_updated.connect(_update_fuseki_data)

	if OS.has_feature("web"):
		print("Detected running on the web")
		# Hide native-only UI elements that are not relevant in the web build.
		$ControlLayer/ControlPanel.hide()

		# Give the embedding page a moment to populate its data before polling.
		get_tree().create_timer(1.0).timeout.connect(_check_for_data)
	else:
		# In native builds, RabbitMQ drives live data updates.
		RabbitMq.set_fuseki_data_manager(fuseki_data)


## Polls the embedding web page for YAML data exposed on `window.parent.dataReady`.
## Retries every 0.5 s until data is available.
func _check_for_data() -> void:
	print("🔍 Checking for YAML data...")

	var js_code := """
	(function() {
		// Return the pre-loaded data string if the parent page has it ready.
		if (window.parent && window.parent.dataReady) {
			return window.parent.dataReady;
		}
		return null;
	})()
	"""

	var window = JavaScriptBridge.get_interface("window")
	var result = window.eval(js_code)

	if result:
		print("💡 Found YAML data")
		fuseki_dumper.load_from_dump(fuseki_data, result)
	else:
		print("⏳ No data yet, will try again...")
		get_tree().create_timer(0.5).timeout.connect(_check_for_data)


## Called when `FusekiSignals.fuseki_data_updated` fires; pushes fresh data
## into the DT container so the visualisation re-renders.
func _update_fuseki_data() -> void:
	dt_container.feed_fuseki_data(fuseki_data)
