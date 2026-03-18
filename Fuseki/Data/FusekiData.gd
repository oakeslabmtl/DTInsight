## Central data store for all information retrieved from the Fuseki triple store.
##
## Responsibilities:
##   - Receive raw JSON responses from Fuseki queries (via input_data_from_fuseki_JSON).
##   - Parse and store them into typed GDScript dictionaries and arrays.
##   - Derive directed relationship arrays (e.g. model → enabler) after each update.
##   - Provide a clean slate via empty() before each new query cycle.
##
## Data layout per entity dictionary:
##   { "<entity_name>": { "<attribute_name>": ["<value>", ...], ... }, ... }

extends Node

class_name FusekiData


## Represents a directed link between two entities, identified by name.
class GenericLinkedNodes:
	var source: String
	var destination: String


## Internal intermediate structure used during JSON parsing.
## Holds one column value from a SPARQL result row.
class JsonValue:
	var json_name: String
	var json_value: String


# ── DTDF entity dictionaries ──────────────────────────────────────────────────
var service: Dictionary
var enabler: Dictionary
var model: Dictionary
var provided_thing: Dictionary
var data_transmitted: Dictionary
var sensing_component: Dictionary
var env: Dictionary
var sys_component: Dictionary
var data: Dictionary

# ── DT characteristic dictionaries (numbered per the DTDF taxonomy) ───────────
var c1: Dictionary   # System under study
var c2: Dictionary   # Physical acting components
var c4: Dictionary   # Physical-to-virtual interaction
var c5: Dictionary   # Virtual-to-physical interaction
var c7: Dictionary   # Twinning time-scale
var c8: Dictionary   # Multiplicities
var c9: Dictionary   # Life-cycle stages
var c12: Dictionary  # DT constellation
var c13: Dictionary  # Twinning process and evolution
var c14: Dictionary  # Fidelity and validity
var c15: Dictionary  # DT technical connection
var c16: Dictionary  # DT hosting/deployment
var c18: Dictionary  # Horizontal integration
var c19: Dictionary  # Data ownership and privacy
var c20: Dictionary  # Standardization
var c21: Dictionary  # Security and safety

# ── Derived directed-relationship arrays ──────────────────────────────────────
var service_to_provided_thing: Array[GenericLinkedNodes]
var enabler_to_service: Array[GenericLinkedNodes]
var model_to_enabler: Array[GenericLinkedNodes]
var sensor_to_data_transmitted: Array[GenericLinkedNodes]
var data_to_enabler: Array[GenericLinkedNodes]
var data_transmitted_to_data: Array[GenericLinkedNodes]

# ── RabbitMQ entity dictionaries ──────────────────────────────────────────────
var rabbit_exchange: Dictionary
var rabbit_route: Dictionary
var rabbit_source: Dictionary
var rabbit_message_listener: Dictionary


func _ready() -> void:
	FusekiSignals.fuseki_data_updated.connect(_on_data_updated)
	FusekiSignals.fuseki_data_clear.connect(empty)


func _on_data_updated() -> void:
	build_relations()


## Receives a raw Fuseki JSON response for a single SPARQL query and routes
## the parsed result into the appropriate member variable.
##
## Expected JSON shape:
##   { "head": { "vars": ["<entity>", "attribute", "value"] },
##     "results": { "bindings": [...] } }
func input_data_from_fuseki_JSON(json) -> void:
	if json == null:
		printerr("Incorrect JSON: it is null")
		return
	if json["head"]["vars"].size() != 3:
		printerr("Incorrect JSON head: expected [\"<variable>\", \"attribute\", \"value\"]")
		return

	# The first variable name identifies which entity type this query covers.
	var json_variable: String = json["head"]["vars"][0]
	var value = parse_fuseki_json(json)

	# Map the SPARQL variable name to the corresponding FusekiData member.
	var targets := {
		FusekiConfig.JsonHead.SERVICE:                "service",
		FusekiConfig.JsonHead.ENABLER:                "enabler",
		FusekiConfig.JsonHead.MODEL:                  "model",
		FusekiConfig.JsonHead.DATA_TRANSMITTED:       "data_transmitted",
		FusekiConfig.JsonHead.PROVIDED:               "provided_thing",
		FusekiConfig.JsonHead.SENSOR:                 "sensing_component",
		FusekiConfig.JsonHead.ENV:                    "env",
		FusekiConfig.JsonHead.SYSTEM_COMPONENT:       "sys_component",
		FusekiConfig.JsonHead.DATA:                   "data",
		FusekiConfig.JsonHead.RABBIT_EXCHANGE:        "rabbit_exchange",
		FusekiConfig.JsonHead.RABBIT_ROUTE:           "rabbit_route",
		FusekiConfig.JsonHead.RABBIT_SOURCE:          "rabbit_source",
		FusekiConfig.JsonHead.RABBIT_MESSAGE_LISTENER:"rabbit_message_listener",
		FusekiConfig.JsonHead.C1:  "c1",
		FusekiConfig.JsonHead.C2:  "c2",
		FusekiConfig.JsonHead.C4:  "c4",
		FusekiConfig.JsonHead.C5:  "c5",
		FusekiConfig.JsonHead.C7:  "c7",
		FusekiConfig.JsonHead.C8:  "c8",
		FusekiConfig.JsonHead.C9:  "c9",
		FusekiConfig.JsonHead.C12: "c12",
		FusekiConfig.JsonHead.C13: "c13",
		FusekiConfig.JsonHead.C14: "c14",
		FusekiConfig.JsonHead.C15: "c15",
		FusekiConfig.JsonHead.C16: "c16",
		FusekiConfig.JsonHead.C18: "c18",
		FusekiConfig.JsonHead.C19: "c19",
		FusekiConfig.JsonHead.C20: "c20",
		FusekiConfig.JsonHead.C21: "c21",
	}

	if targets.has(json_variable):
		set(targets[json_variable], value)


## Parses a Fuseki JSON response into either:
##   - A Dictionary  (when is_link = false, the default) — for entity data.
##   - An Array[GenericLinkedNodes] (when is_link = true) — for relationship data.
static func parse_fuseki_json(json, is_link: bool = false):
	var json_head = json["head"]["vars"]
	var json_results = json["results"]["bindings"]
	var result_aggregator := []

	for result in json_results:
		if result == null:
			break
		var tuple_aggregator := []
		for head in json_head:
			if result.has(head):
				var new_json_value := JsonValue.new()
				new_json_value.json_name = head
				new_json_value.json_value = parse_fuseki_value(result[head]["value"])
				tuple_aggregator.append(new_json_value)
		result_aggregator.append(tuple_aggregator)

	return parse_link_result(result_aggregator) if is_link else parse_element_result(result_aggregator)


## Strips the namespace prefix from a URI value, keeping only the fragment
## after '#'. Non-URI values are returned unchanged.
static func parse_fuseki_value(value: String) -> String:
	if value.contains("#"):
		return value.split("#")[1]
	return value


## Converts a flat result aggregator into an Array[GenericLinkedNodes].
## Expects each inner array to have exactly two JsonValue entries:
##   [0] = source entity name, [1] = destination entity name.
static func parse_link_result(result_aggregator) -> Array[GenericLinkedNodes]:
	var formatted_result: Array[GenericLinkedNodes] = []
	for result in result_aggregator:
		var link := GenericLinkedNodes.new()
		link.source = result[0].json_value
		link.destination = result[1].json_value
		formatted_result.append(link)
	return formatted_result


## Converts a flat result aggregator into a nested Dictionary of the form:
##   { "<entity>": { "<attribute>": ["<value>", ...], ... }, ... }
## Multiple rows for the same entity are merged; multiple values for the same
## attribute are accumulated into an array.
static func parse_element_result(result_aggregator) -> Dictionary:
	var formatted_result: Dictionary = {}
	for result in result_aggregator:
		var entry_name: String = result[0].json_value
		if not formatted_result.has(entry_name):
			formatted_result[entry_name] = {}
		var attribute_name: String = result[1].json_value
		var attribute_value: String = result[2].json_value
		if attribute_name in formatted_result[entry_name].keys():
			formatted_result[entry_name][attribute_name].append(attribute_value)
		else:
			formatted_result[entry_name].merge({attribute_name: [attribute_value]})
	return formatted_result


## Rebuilds all directed-relationship arrays from the current entity data.
## Called automatically whenever FusekiSignals.fuseki_data_updated fires.
func build_relations() -> void:
	model_to_enabler           = build_relations_from(model,          FusekiConfig.RelationAttribute.MODEL_TO_ENABLER)
	enabler_to_service         = build_relations_from(enabler,        FusekiConfig.RelationAttribute.ENABLER_TO_SERVICE)
	service_to_provided_thing  = build_relations_from(service,        FusekiConfig.RelationAttribute.SERVICES_TO_PROVIDED)
	sensor_to_data_transmitted = build_relations_from(data_transmitted,FusekiConfig.RelationAttribute.SENSOR_TO_DATA_TRANSMITTED, true)
	data_transmitted_to_data   = build_relations_from(data,           FusekiConfig.RelationAttribute.DATA_TRANSMITTED_TO_DATA, true)
	data_to_enabler            = build_relations_from(data,           FusekiConfig.RelationAttribute.DATA_TO_ENABLER)


## Derives a relationship array from an entity dictionary by inspecting a
## specific link attribute.
##
## [param element_data]   The source entity dictionary to scan.
## [param link_attribute] The attribute name whose values are linked entity names.
## [param inversed]       When true, the linked-entity name becomes the source
##                        and the owning entity becomes the destination. Useful
##                        when the relation is stored on the "wrong" side of the edge.
func build_relations_from(
	element_data: Dictionary,
	link_attribute: String,
	inversed: bool = false
) -> Array[GenericLinkedNodes]:
	var resulting_relations: Array[GenericLinkedNodes] = []
	for element_name in element_data.keys():
		if link_attribute in element_data[element_name]:
			var relation_list: Array = element_data[element_name][link_attribute]
			for linked_name in relation_list:
				var new_relation := GenericLinkedNodes.new()
				new_relation.source      = element_name if not inversed else linked_name
				new_relation.destination = linked_name  if not inversed else element_name
				resulting_relations.append(new_relation)
	return resulting_relations


## Clears all cached entity data, characteristic data, relationship arrays,
## and RabbitMQ data. Called before each new Fuseki query cycle.
func empty() -> void:
	# DTDF entities
	service           = {}
	enabler           = {}
	model             = {}
	provided_thing    = {}
	data_transmitted  = {}
	sensing_component = {}
	env               = {}
	sys_component     = {}
	data              = {}

	# Relationship arrays
	service_to_provided_thing  = []
	enabler_to_service         = []
	model_to_enabler           = []
	sensor_to_data_transmitted = []
	data_to_enabler            = []
	data_transmitted_to_data   = []

	# RabbitMQ entities
	rabbit_exchange         = {}
	rabbit_route            = {}
	rabbit_source           = {}
	rabbit_message_listener = {}


## Convenience wrapper: dumps the architecture to [param dump_path] via
## [FusekiDataDumper]. Pass [param to_console] = true to print instead.
func dump(dump_path: String, to_console: bool = false) -> void:
	FusekiDataDumper.dump_architecture(self, dump_path, to_console)
