## Catalogue of SPARQL queries used to retrieve Digital Twin Description Framework
## (DTDF) data from the Fuseki triple store.
##
## All queries follow the same three-column SELECT pattern:
##   ?<entity>  ?attribute  ?value
## which maps directly to the FusekiData parsing pipeline.

extends Node

var QUERIES: Dictionary = {}

const PREFIXES = {
	"DTDFvocab": "<https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>",
	"rdfs": "<http://www.w3.org/2000/01/rdf-schema#>",
	"base": "<https://bentleyjoakes.github.io/DTDF/vocab/base#>",
	"rabbit": "<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>"
}

const TEMPLATES = {
	"standard": """PREFIX DTDFvocab: {DTDFvocab}
PREFIX rdfs: {rdfs}
PREFIX base: {base}

SELECT * WHERE {{
	?{alias} a {rdf_type} .
	OPTIONAL {{?{alias} ?attribute ?value}}
}}""",

	"env": """PREFIX DTDFvocab: {DTDFvocab}
PREFIX rdfs: {rdfs}
PREFIX base: {base}

SELECT ?env ?attribute ?value WHERE {{
	?sus a DTDFvocab:SystemUnderStudy .
	?sus DTDFvocab:hasEnvironment ?envS .
	?env base:isContainedIn ?envS .
	OPTIONAL {{?env ?attribute ?value}}
}}""",

	"sys_component": """PREFIX DTDFvocab: {DTDFvocab}
PREFIX rdfs: {rdfs}
PREFIX base: {base}

SELECT ?sysComponent ?attribute ?value WHERE {{
	?sus a DTDFvocab:SystemUnderStudy .
	?sus DTDFvocab:hasSystem ?sys .
	?sysComponent base:isContainedIn ?sys .
	OPTIONAL {{?sysComponent ?attribute ?value}}
}}""",

	"rabbit": """PREFIX rabbit: {rabbit}

SELECT ?{alias} ?attribute ?value WHERE {{
	?{alias} a {rdf_type} .
	?{alias} ?attribute ?value
}}"""
}

# ── Metadata for Query Generation ──────────────────────────────────────────────
const QUERY_METADATA = [
	{ id = "services", alias = "service", type = "DTDFvocab:Service" },
	{ id = "enablers", alias = "enabler", type = "DTDFvocab:Enabler" },
	{ id = "models", alias = "model", type = "DTDFvocab:Model" },
	{ id = "provided_things", alias = "provided", type = "DTDFvocab:ProvidedThing" },
	{ id = "data_transmitted", alias = "dataT", type = "DTDFvocab:DataTransmitted" },
	{ id = "data", alias = "data", type = "DTDFvocab:Data" },
	{ id = "sensors", alias = "sensor", type = "DTDFvocab:SensingComponent" },
	
	# Explicit template queries
	{ id = "env", template = "env" },
	{ id = "sys_component", template = "sys_component" },

	# RabbitMQ
	{ id = "rabbit_exchange", alias = "exc", type = "rabbit:ExchangeName", template = "rabbit" },
	{ id = "rabbit_routing_key", alias = "route", type = "rabbit:RoutingKey", template = "rabbit" },
	{ id = "rabbit_source", alias = "source", type = "rabbit:Source", template = "rabbit" },
	{ id = "rabbit_message_listener", alias = "ml", type = "rabbit:MessageListener", template = "rabbit" },

	# Misc
	{ id = "time_scales", alias = "ts", type = "DTDFvocab:TimeScale" },

	# Characteristics
	{ id = "characteristic_system_under_study", alias = "c1", type = "DTDFvocab:SystemUnderStudy" },
	{ id = "characteristic_acting_component", alias = "c2", type = "DTDFvocab:ActingComponent" },
	{ id = "characteristic_data_transmitted", alias = "c4", type = "DTDFvocab:DataTransmitted" },
	{ id = "characteristic_virtual_to_physical", alias = "c5", type = "DTDFvocab:VirtualToPhysical" },
	{ id = "characteristic_time_scale", alias = "c7", type = "DTDFvocab:TimeScale" },
	{ id = "characteristic_multiplicity", alias = "c8", type = "DTDFvocab:Multiplicity" },
	{ id = "characteristic_life_cycle_stage", alias = "c9", type = "DTDFvocab:LifeCycleStage" },
	{ id = "characteristic_constellation", alias = "c12", type = "DTDFvocab:Constellation" },
	{ id = "characteristic_evolution_stage", alias = "c13", type = "DTDFvocab:EvolutionStage" },
	{ id = "characteristic_fidelity_consideration", alias = "c14", type = "DTDFvocab:FidelityConsideration" },
	{ id = "characteristic_technical_connection", alias = "c15", type = "DTDFvocab:TechnicalConnection" },
	{ id = "characteristic_deployment", alias = "c16", type = "DTDFvocab:Deployment" },
	{ id = "characteristic_horizontal_integration", alias = "c18", type = "DTDFvocab:HoriIntegration" },
	{ id = "characteristic_data_ownership", alias = "c19", type = "DTDFvocab:DataOwnershipPrivacy" },
	{ id = "characteristic_standardization", alias = "c20", type = "DTDFvocab:Standardization" },
	{ id = "characteristic_security_safety", alias = "c21", type = "DTDFvocab:SecuritySafety" }
]

func _init() -> void:
	for meta in QUERY_METADATA:
		QUERIES[meta.id] = _build_query(meta)

func _build_query(meta: Dictionary) -> String:
	var template_name = meta.get("template", "standard")
	var format_data = PREFIXES.duplicate()
	format_data["alias"] = meta.get("alias", "")
	format_data["rdf_type"] = meta.get("type", "")
	return TEMPLATES[template_name].format(format_data)
