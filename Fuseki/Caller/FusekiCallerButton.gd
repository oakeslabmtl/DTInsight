## Button that triggers a full Fuseki SPARQL query cycle.
## On press it:
##   1. Auto-detects named graphs and write graph if not yet known.
##   2. Clears existing data via FusekiSignals.
##   3. Iterates over every query defined in FusekiQuery.QUERIES sequentially,
##      awaiting each HTTP response before firing the next.
##   4. Emits FusekiSignals.fuseki_data_updated once all responses are processed.

extends Button

@onready var sparql_request = $SparqlFusekiQueries
@onready var fuseki_query_manager = $SparqlFusekiQueries/FusekiQuery

var fuseki_data_manager: FusekiData

## Tracks which discovery phase we're in so _on_fuseki_completion can route
## the response correctly.  "" means normal query mode.
var _discovery_phase := ""


## Injects the shared [FusekiData] manager used to store parsed query results.
func set_fuseki_data_manager(manager: FusekiData) -> void:
	fuseki_data_manager = manager


func _on_pressed() -> void:
	# Auto-detect graphs on first run.
	if FusekiConfig.DEFAULT_WRITE_GRAPH_PREFIX == "":
		await _discover_graphs()

	# Signal all listeners to clear stale data before the new query cycle.
	FusekiSignals.fuseki_data_clear.emit()

	# Disable the button for the duration of the query cycle to prevent
	# overlapping requests.
	disabled = true

	# Fire each SPARQL query in sequence; await ensures one completes before
	# the next begins so FusekiData is populated in a deterministic order.
	for query_name in fuseki_query_manager.QUERIES.keys():
		var query: String = fuseki_query_manager.QUERIES[query_name]
		_send_query(query)
		await sparql_request.request_completed

	FusekiSignals.fuseki_data_updated.emit()
	disabled = false


## Sends a single URL-encoded SPARQL query to the configured Fuseki endpoint.
func _send_query(query: String) -> void:
	sparql_request.request(
		FusekiConfig.URL + FusekiConfig.DATASET + FusekiConfig.ENDPOINT + query.uri_encode()
	)


## Graph discovery: Query all named graphs → build GRAPH_PREFIXES
func _discover_graphs() -> void:
	_discovery_phase = "all_graphs"
	_send_query(FusekiConfig.GRAPH_DETECT_QUERY)
	await sparql_request.request_completed
	_discovery_phase = ""


## Callback connected to the HTTPRequest node's `request_completed` signal.
## Routes graph-discovery responses separately from normal query responses.
func _on_fuseki_completion(_result, _response_code, _headers, body) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	if json == null:
		return

	if _discovery_phase == "all_graphs":
		var bindings = json.get("results", {}).get("bindings", [])
		for binding in bindings:
			if binding.has("g"):
				var graph_uri: String = binding["g"]["value"]
				var prefix_name := FusekiConfig._prefix_from_uri(graph_uri)
				# Avoid collisions with existing prefixes
				if prefix_name not in FusekiConfig.GRAPH_PREFIXES:
					FusekiConfig.GRAPH_PREFIXES[prefix_name] = "<%s#>" % graph_uri
				
				# Set the first discovered graph as the global fallback
				if FusekiConfig.DEFAULT_WRITE_GRAPH_PREFIX == "":
					FusekiConfig.DEFAULT_WRITE_GRAPH_PREFIX = prefix_name
					print("FusekiCallerButton: Fallback write graph prefix set to '", prefix_name, "'")
					
		print("FusekiCallerButton: Discovered graph prefixes: ", FusekiConfig.GRAPH_PREFIXES.keys())
		return

	# Normal query: forward to FusekiData
	fuseki_data_manager.input_data_from_fuseki_JSON(json)
