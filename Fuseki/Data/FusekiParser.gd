## stateless utility class for parsing
class_name FusekiParser

## Internal intermediate structure used during JSON parsing.
## Holds one column value from a SPARQL result row.
class JsonValue:
	var json_name: String
	var json_value: String


## Parses a Fuseki JSON response into either:
##   - A Dictionary  (when is_link = false, the default) — for entity data.
##   - An Array[FusekiData.GenericLinkedNodes] (when is_link = true) — for relationship data.
static func parse_fuseki_json(json: Dictionary, is_link: bool = false):
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


## Converts a flat result aggregator into an Array[FusekiData.GenericLinkedNodes].
## Expects each inner array to have exactly two JsonValue entries.
static func parse_link_result(result_aggregator: Array) -> Array[FusekiData.GenericLinkedNodes]:
	var formatted_result: Array[FusekiData.GenericLinkedNodes] = []
	for result in result_aggregator:
		var link := FusekiData.GenericLinkedNodes.new()
		link.source = result[0].json_value
		link.destination = result[1].json_value
		formatted_result.append(link)
	return formatted_result


## Converts a flat result aggregator into a nested Dictionary.
static func parse_element_result(result_aggregator: Array) -> Dictionary:
	var formatted_result: Dictionary = {}
	for result in result_aggregator:
		var entry_name: String = result[0].json_value
		if not formatted_result.has(entry_name):
			formatted_result[entry_name] = {}
		if result.size() >= 3:
			var attribute_name: String = result[1].json_value
			var attribute_value: String = result[2].json_value
			if attribute_name in formatted_result[entry_name]:
				formatted_result[entry_name][attribute_name].append(attribute_value)
			else:
				formatted_result[entry_name][attribute_name] = [attribute_value]
	return formatted_result
