extends Node

#Fuseki endpoint data
var URL = "http://127.0.0.1:3030" #Fuseki server, localhost if started from openCAESAR on this machine
var DATASET = "/DTDF" #FUseki endpoint defined in fuseki.ttl in the project
var ENDPOINT = "/sparql?query=" #sparql endpoint

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
