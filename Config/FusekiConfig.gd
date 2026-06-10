extends Node

#Fuseki endpoint data
var URL = "http://127.0.0.1:3030" #Fuseki server, localhost if started from openCAESAR on this machine
var DATASET = "/DTDF" #FUseki endpoint defined in fuseki.ttl in the project
var ENDPOINT = "/sparql?query=" #sparql endpoint
var UPDATE_ENDPOINT = "/update" #sparql update endpoint (POST only)
## Fallback prefix used when writing a completely new entity type that
## wasn't found in CLASS_TO_GRAPH_PREFIX.
var DEFAULT_WRITE_GRAPH_PREFIX := ""

## Dynamic graph-derived prefix map: { "prefix_name": "<full_uri#>" }
## Populated at startup by querying all named graphs in Fuseki.
var GRAPH_PREFIXES: Dictionary = {}

## SPARQL query to discover all named graphs.
const GRAPH_DETECT_QUERY = """SELECT DISTINCT ?g WHERE {
  GRAPH ?g { ?s ?p ?o }
}"""



## Derives a short prefix name from a graph URI.
## e.g. "https://bentleyjoakes.github.io/incubator/incubator_dt" → "incubator_dt"
## e.g. "https://bentleyjoakes.github.io/DTDF/desc/baseDesc"    → "baseDesc"
static func _prefix_from_uri(uri: String) -> String:
	# Strip trailing / or #
	var clean := uri.rstrip("/#")
	var last_slash := clean.rfind("/")
	var prefix := clean
	if last_slash >= 0:
		prefix = clean.substr(last_slash + 1)
	
	# Sanitize for SPARQL: replace invalid characters
	prefix = prefix.replace(".", "_").replace("-", "_")
	
	# SPARQL prefixes must start with a letter
	if prefix.length() > 0 and "0123456789".find(prefix[0]) >= 0:
		prefix = "ns_" + prefix
		
	return prefix

#JSON match
class JsonHead:
	const SERVICE = "service"
	const ENABLER = "enabler"
	const MODEL = "model"
	const DATA_TRANSMITTED = "dataT"
	const DATA = "data"
	const PROVIDED = "provided"
	const SENSOR = "sensor"
	const ENV = "env"
	const SYSTEM_COMPONENT = "sysComponent"
	const RABBIT_EXCHANGE = "exc"
	const RABBIT_ROUTE = "route"
	const RABBIT_SOURCE = "source"
	const RABBIT_MESSAGE_LISTENER = "ml"
	const TIMESCALES = "ts"
	const C1 = "c1"
	const C2 = "c2"
	const C4 = "c4"
	const C5 = "c5"
	const C7 = "c7"
	const C8 = "c8"
	const C9 = "c9"
	const C12 = "c12"
	const C13 = "c13"
	const C14 = "c14"
	const C15 = "c15"
	const C16 = "c16"
	const C18 = "c18"
	const C19 = "c19"
	const C20 = "c20"
	const C21 = "c21"

class RelationAttribute:
	const MODEL_TO_ENABLER = "inputTo"
	const ENABLER_TO_SERVICE = "enables"
	const SERVICES_TO_PROVIDED = "provides"
	const SENSOR_TO_DATA_TRANSMITTED = "producedFrom"
	const DATA_TO_ENABLER = "inputTo"
	const DATA_TRANSMITTED_TO_DATA = "fromData"
