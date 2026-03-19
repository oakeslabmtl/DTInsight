## Button that triggers a full Fuseki SPARQL query cycle.
## On press it:
##   1. Clears existing data via FusekiSignals.
##   2. Iterates over every query defined in FusekiQuery.QUERIES sequentially,
##      awaiting each HTTP response before firing the next.
##   3. Emits FusekiSignals.fuseki_data_updated once all responses are processed.

extends Button

@onready var sparql_request = $SparqlFusekiQueries
@onready var fuseki_query_manager = $SparqlFusekiQueries/FusekiQuery

var fuseki_data_manager: FusekiData


## Injects the shared [FusekiData] manager used to store parsed query results.
func set_fuseki_data_manager(manager: FusekiData) -> void:
	fuseki_data_manager = manager


func _on_pressed() -> void:
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


## Callback connected to the HTTPRequest node's `request_completed` signal.
## Parses the JSON body and forwards the result to the FusekiData manager.
func _on_fuseki_completion(_result, _response_code, _headers, body) -> void:
	var json = JSON.parse_string(body.get_string_from_utf8())
	fuseki_data_manager.input_data_from_fuseki_JSON(json)
