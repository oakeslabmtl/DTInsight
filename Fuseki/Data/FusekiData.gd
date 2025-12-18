extends Node

class_name FusekiData

#Represent a link between two elements by their names
class GenericLinkedNodes:
	var source: String
	var destination: String

#Internal data stucture
class JsonValue:
	var json_name: String
	var json_value : String

#Store parsed values from Fuseki
var service : Dictionary
var enabler : Dictionary
var model : Dictionary
var provided_thing : Dictionary
var data_transmitted : Dictionary
var sensing_component : Dictionary
var env : Dictionary
var sys_component : Dictionary
var data : Dictionary
var c1 : Dictionary
var c2 : Dictionary
var c4 : Dictionary
var c5 : Dictionary
var c7 : Dictionary
var c8 : Dictionary
var c9 : Dictionary
var c12 : Dictionary
var c13 : Dictionary
var c14 : Dictionary
var c15 : Dictionary
var c16 : Dictionary
var c18 : Dictionary
var c19 : Dictionary
var c20 : Dictionary
var c21 : Dictionary

var service_to_provided_thing : Array[GenericLinkedNodes]
var enabler_to_service : Array[GenericLinkedNodes]
var model_to_enabler : Array[GenericLinkedNodes]
var sensor_to_data_transmitted : Array[GenericLinkedNodes]
var data_to_enabler : Array[GenericLinkedNodes]
var data_transmitted_to_data : Array[GenericLinkedNodes]

var rabbit_exchange : Dictionary
var rabbit_route : Dictionary
var rabbit_source : Dictionary
var rabbit_message_listener : Dictionary

func _ready():
	FusekiSignals.fuseki_data_updated.connect(_on_data_updated)
	FusekiSignals.fuseki_data_clear.connect(empty)

func _on_data_updated():
	build_relations()

# Take a JSON from a Fuseki query and store the resulting information in 
# variables reachable from the Godot application
func input_data_from_fuseki_JSON(json):
	if json == null:
		printerr("Incorrect JSON: It is null")
		return
	if json["head"]["vars"].size() != 3:
		printerr("Incorrect JSON head: should be [\"<variable>\", \"attribute\", \"value\"]")
		return
	
	var json_variable : String = json["head"]["vars"][0]
	var value = parse_fuseki_json(json)
		
	var targets = {
		FusekiConfig.JsonHead.SERVICE: "service",
		FusekiConfig.JsonHead.ENABLER: "enabler",
		FusekiConfig.JsonHead.MODEL: "model",
		FusekiConfig.JsonHead.DATA_TRANSMITTED: "data_transmitted",
		FusekiConfig.JsonHead.PROVIDED: "provided_thing",
		FusekiConfig.JsonHead.SENSOR: "sensing_component",
		FusekiConfig.JsonHead.ENV: "env",
		FusekiConfig.JsonHead.SYSTEM_COMPONENT: "sys_component",
		FusekiConfig.JsonHead.DATA: "data",
		FusekiConfig.JsonHead.RABBIT_EXCHANGE: "rabbit_exchange",
		FusekiConfig.JsonHead.RABBIT_ROUTE: "rabbit_route",
		FusekiConfig.JsonHead.RABBIT_SOURCE: "rabbit_source",
		FusekiConfig.JsonHead.RABBIT_MESSAGE_LISTENER: "rabbit_message_listener",
		FusekiConfig.JsonHead.C1: "c1",
		FusekiConfig.JsonHead.C2: "c2",
		FusekiConfig.JsonHead.C4: "c4",
		FusekiConfig.JsonHead.C5: "c5",
		FusekiConfig.JsonHead.C7: "c7",
		FusekiConfig.JsonHead.C8: "c8",
		FusekiConfig.JsonHead.C9: "c9",
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
		set(targets[json_variable], value) # Fill the variables with data


#Parse the json from Fuseki into internal data structure
#Return an Array of GenericLinkedNodes or a Dictionary depending on the data type
static func parse_fuseki_json(json, is_link = false):
	var json_head = json["head"]["vars"]
	var json_results = json["results"]["bindings"]
	var result_aggregator: = []
	for result in json_results:
		if (result == null):
			break
		var tuple_aggregator = []
		for head in json_head:
			if (result.has(head)):
				var new_json_value = JsonValue.new()
				new_json_value.json_name = head
				new_json_value.json_value = parse_fuseki_value(result[head]["value"])
				tuple_aggregator.append(new_json_value)
		result_aggregator.append(tuple_aggregator)
	#Transform the result agregator in an array of GenericLinkedNodes or
	#in a dictionary depending on the data type
	return parse_link_result(result_aggregator) if (is_link) else parse_element_result(result_aggregator)

#Remove oml link data from values
static func parse_fuseki_value(value) -> String:
	if(value.contains("#")):
		return value.split("#")[1]
	return value

#Transform the result agregator in an Array of GenericLinkedNodes
static func parse_link_result(result_agregator) -> Array[GenericLinkedNodes]:
	var formated_result : Array[GenericLinkedNodes] = []
	for result in result_agregator:
		var link = GenericLinkedNodes.new()
		link.first_node_name = result[0].json_value
		link.second_node_name = result[1].json_value
		formated_result.append(link)
	return formated_result

#Transform the result agregator in a dictionary, in each entry corresponding 
#to an element is a disctionary containing every attributes of this element
static func parse_element_result(result_agregator) -> Dictionary:
	var formated_result : Dictionary = {}
	for result in result_agregator:
		var entry_name = result[0].json_value
		if (not formated_result.has(entry_name)):
			formated_result[entry_name] = {}
		var attribute_name = result[1].json_value
		var attribute_value = result[2].json_value
		if attribute_name in formated_result[entry_name].keys() :
			formated_result[entry_name][attribute_name].append(attribute_value)
		else:
			var entry_value : Dictionary = {}
			entry_value[attribute_name] = [attribute_value]
			formated_result[entry_name].merge(entry_value)
	return formated_result

#Build relations attributes
func build_relations():
	model_to_enabler = build_relations_from(model, FusekiConfig.RelationAttribute.MODEL_TO_ENABLER)
	enabler_to_service = build_relations_from(enabler, FusekiConfig.RelationAttribute.ENABLER_TO_SERVICE)
	service_to_provided_thing = build_relations_from(service, FusekiConfig.RelationAttribute.SERVICES_TO_PROVIDED)
	sensor_to_data_transmitted = build_relations_from(data_transmitted, FusekiConfig.RelationAttribute.SENSOR_TO_DATA_TRANSMITTED, true)
	data_transmitted_to_data = build_relations_from(data, FusekiConfig.RelationAttribute.DATA_TRANSMITTED_TO_DATA, true)
	data_to_enabler = build_relations_from(data, FusekiConfig.RelationAttribute.DATA_TO_ENABLER)

#Build relations between two elements from attributes
func build_relations_from(element_data : Dictionary, link_attribute : String, inversed : bool = false) -> Array[GenericLinkedNodes]:
	var resulting_relations : Array[GenericLinkedNodes] = []
	for element_name in element_data.keys():
		if (link_attribute in element_data[element_name]):
			var relation_list : Array = element_data[element_name][link_attribute]
			for linked_name in relation_list:
				var new_relation : GenericLinkedNodes = GenericLinkedNodes.new()
				new_relation.source = element_name if (not inversed) else linked_name
				new_relation.destination = linked_name if (not inversed) else element_name
				resulting_relations.append(new_relation)
	return resulting_relations

#Empty all elements and relations
func empty():
	service = {}
	enabler = {}
	model = {}
	provided_thing = {}
	data_transmitted = {}
	sensing_component = {}
	env = {}
	sys_component = {}
	data = {}
	
	service_to_provided_thing = []
	enabler_to_service = []
	model_to_enabler = []
	sensor_to_data_transmitted = []
	data_to_enabler = []
	data_transmitted_to_data = []
	
	rabbit_exchange = {}
	rabbit_route = {}
	rabbit_source = {}
	rabbit_message_listener = {}

#Call dump function
func dump(dump_path : String, to_console : bool = false):
	FusekiDataDumper.dump_architecture(self, dump_path, to_console)
