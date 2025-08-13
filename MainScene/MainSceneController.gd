extends Node
#scene ressources
@onready var fuseki_caller = %FusekiCallerButton
@onready var fuseki_dumper = $ControlLayer/SettingsBackground/Settings/%FusekiDumperController
@onready var fuseki_data : FusekiData = $FusekiData
@onready var dt_container : BoxContainer = $DTContainer

func _ready():
	fuseki_caller.set_fuseki_data_manager(fuseki_data)
	fuseki_dumper.set_fuseki_data_manager(fuseki_data)
	FusekiSignals.fuseki_data_updated.connect(_update_fuseki_data)
	
	if OS.has_feature("web"):
		print("Detected running on the web")
		$ControlLayer.hide()
		# Start checking for data after a short delay
		get_tree().create_timer(1.0).timeout.connect(_check_for_data)
	else:
		RabbitMq.set_fuseki_data_manager(fuseki_data)

func _check_for_data():
	print("🔍 Checking for YAML data...")
	
	var js_code = """
	(function() {
		// Check if parent window has data ready
		if (window.parent && window.parent.dataReady) {
			return window.parent.dataReady;
		}
		return null;
	})()
	"""
	
	var window = JavaScriptBridge.get_interface("window")
	var result = window.eval(js_code)
	
	if result and result != null:
		print("💡 Found YAML data")
		fuseki_dumper.load_from_dump(fuseki_data, result)
	else:
		print("⏳ No data yet, will try again...")
		# Try again in 0.5 seconds
		get_tree().create_timer(0.5).timeout.connect(_check_for_data)

func _update_fuseki_data():
	dt_container.feed_fuseki_data(fuseki_data)

func load_yaml_from_dump():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(self._on_HTTPRequest_yaml_completed)
	# TODO: Fix this hardcoded URL
	var error = http.request("https://oakeslab-polymtl.github.io/DTDF/data_dump.yaml")
	#var error = http.request("http://localhost:1313/DTDF/data_dump.yaml")
	if error != OK:
		push_error("An error occurred in the HTTP request for YAML data.")

func _on_HTTPRequest_yaml_completed(result, response_code, headers, body):
	if response_code == 200:
		var yaml_content = body.get_string_from_utf8()
		fuseki_dumper.load_from_dump(fuseki_data, yaml_content)
		print("YAML data loaded successfully from HTTP request")
	else:
		push_error("Failed to load YAML data. Response code: " + str(response_code))
