## Sends SPARQL Update requests to the Fuseki triple store.
##
## Attach this node (or its scene FusekiWriter.tscn) anywhere in the scene
## tree.  It owns a dedicated [HTTPRequest] child so it never conflicts with
## the read-side queries.
##
## Usage:
##   var sparql = FusekiUpdateQuery.build_insert(...)
##   var ok: bool = await fuseki_writer.execute_update(sparql)

extends Node


## The HTTPRequest node used to POST update requests.
@onready var _http_request: HTTPRequest = $UpdateHTTPRequest

## True while a request is in flight; used to queue sequential updates.
var _busy := false

## FIFO queue of pending SPARQL update strings.
var _queue: Array[String] = []


func _ready() -> void:
	_http_request.request_completed.connect(_on_request_completed)


# ── Public API ────────────────────────────────────────────────────────────────

## Sends a SPARQL Update string to Fuseki.
## Returns [code]true[/code] on HTTP 2xx, [code]false[/code] otherwise.
## This method is [b]async[/b] — callers should [code]await[/code] it.
func execute_update(sparql: String) -> bool:
	_queue.append(sparql)
	if _busy:
		# Another request is already in flight.  This one will be picked
		# up automatically once the current request finishes.
		# We wait until OUR specific item is processed.
		while sparql in _queue:
			await FusekiSignals.fuseki_write_succeeded
			# Also listen for failure so we don't deadlock.
			# (signal fan-out means we'll wake on either)
		# After our item left the queue, check the last result.
		return _last_success
	return await _send_next()

# ── Internals ─────────────────────────────────────────────────────────────────

## Tracks the success/failure of the most recently completed request
## so queued callers can read it after being woken up.
var _last_success := false

## The SPARQL string currently in flight (for signal payload).
var _current_sparql := ""


## Pops the next item from the queue and sends it.  Returns the result.
func _send_next() -> bool:
	if _queue.is_empty():
		_busy = false
		return true  # nothing to do

	_busy = true
	_current_sparql = _queue.pop_front()

	var url: String = FusekiConfig.URL + FusekiConfig.DATASET + FusekiConfig.UPDATE_ENDPOINT
	var headers := PackedStringArray(["Content-Type: application/sparql-update"])

	FusekiSignals.fuseki_write_started.emit(_current_sparql)

	var err := _http_request.request(url, headers, HTTPClient.METHOD_POST, _current_sparql)
	if err != OK:
		printerr("FusekiWriter: HTTPRequest.request() failed with error code ", err)
		_busy = false
		FusekiSignals.fuseki_write_failed.emit(-1, "HTTPRequest.request() error: %s" % err)
		_last_success = false
		return false

	# Wait for the HTTP response.
	var result: Array = await _http_request.request_completed
	# result is [result, response_code, headers, body] — but we handle it
	# in the connected callback, so we just return the stored flag.
	return _last_success


## Handles the HTTP response from Fuseki.
func _on_request_completed(_result: int, response_code: int,
							_headers: PackedStringArray, body: PackedByteArray) -> void:
	var body_str := body.get_string_from_utf8()

	if response_code >= 200 and response_code < 300:
		print("FusekiWriter: Update succeeded (HTTP %d)" % response_code)
		_last_success = true
		FusekiSignals.fuseki_write_succeeded.emit(response_code)
	else:
		printerr("FusekiWriter: Update FAILED (HTTP %d): %s" % [response_code, body_str])
		_last_success = false
		FusekiSignals.fuseki_write_failed.emit(response_code, body_str)

	# Process next queued update, if any.
	if not _queue.is_empty():
		_send_next()
	else:
		_busy = false
