## Catalogue of SPARQL queries used to retrieve Digital Twin Description Framework
## (DTDF) data from the Fuseki triple store.
##
## All queries follow the same three-column SELECT pattern:
##   ?<entity>  ?attribute  ?value
## which maps directly to the FusekiData parsing pipeline.
##
## Queries are grouped into three logical sections:
##   1. DTDF / DT–PT objects   – core DT entities defined in DTDFVocab.
##   2. RabbitMQ objects       – messaging infrastructure entities.
##   3. DT Characteristics     – numbered characteristics (C1–C21) from the DTDF taxonomy.

extends Node

const QUERIES = {
	# ── DTDF / DT–PT objects ──────────────────────────────────────────────────

	"services": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?service a DTDFvocab:Service .
		OPTIONAL {?service ?attribute ?value}
	}",

	"enablers": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?enabler a DTDFvocab:Enabler .
		OPTIONAL {?enabler ?attribute ?value}
	}",

	"models": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?model a DTDFvocab:Model .
		OPTIONAL {?model ?attribute ?value}
	}",

	"provided_things": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?provided a DTDFvocab:ProvidedThing .
		OPTIONAL {?provided ?attribute ?value}
	}",

	"data_transmitted": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?dataT a DTDFvocab:DataTransmitted .
		OPTIONAL {?dataT ?attribute ?value}
	}",

	"data": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?data a DTDFvocab:Data .
		OPTIONAL {?data ?attribute ?value}
	}",

	"sensors": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>

	SELECT *
	WHERE {
		?sensor a DTDFvocab:SensingComponent .
		OPTIONAL {?sensor ?attribute ?value}
	}",

	"env": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT ?env ?attribute ?value
	WHERE {
		?sus a DTDFvocab:SystemUnderStudy .
		?sus DTDFvocab:hasEnvironment ?envS .
		?env base:isContainedIn ?envS .
		OPTIONAL {?env ?attribute ?value}
	}",

	"sys_component": "PREFIX DTDFvocab:   <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT ?sysComponent ?attribute ?value
	WHERE {
		?sus a DTDFvocab:SystemUnderStudy .
		?sus DTDFvocab:hasSystem ?sys .
		?sysComponent base:isContainedIn ?sys .
		OPTIONAL {?sysComponent ?attribute ?value}
	}",

	# ── RabbitMQ objects ──────────────────────────────────────────────────────

	"rabbit_exchange": "PREFIX rabbit:		<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>

	SELECT ?exc ?attribute ?value
	WHERE {
		?exc a rabbit:ExchangeName .
		?exc ?attribute ?value
	}",

	"rabbit_routing_key": "PREFIX rabbit:		<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>

	SELECT ?route ?attribute ?value
	WHERE {
		?route a rabbit:RoutingKey  .
		?route ?attribute ?value
	}",

	"rabbit_source": "PREFIX rabbit:		<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>

	SELECT ?source ?attribute ?value
	WHERE {
		?source a rabbit:Source  .
		?source ?attribute ?value
	}",

	"rabbit_message_listener": "PREFIX rabbit:		<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>

	SELECT ?ml ?attribute ?value
	WHERE {
		?ml a rabbit:MessageListener   .
		?ml ?attribute ?value
	}",

	# ── DT Characteristics (C1–C21) ───────────────────────────────────────────

	"characteristic_system_under_study": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c1 a DTDFvocab:SystemUnderStudy  .
		OPTIONAL {?c1 ?attribute ?value}
	}",

	"characteristic_acting_component": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c2 a DTDFvocab:ActingComponent  .
		OPTIONAL {?c2 ?attribute ?value}
	}",

	"characteristic_data_transmitted": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c4 a DTDFvocab:DataTransmitted  .
		OPTIONAL {?c4 ?attribute ?value}
	}",

	"characteristic_virtual_to_physical": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c5 a DTDFvocab:VirtualToPhysical  .
		OPTIONAL {?c5 ?attribute ?value}
	}",

	"characteristic_time_scale": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c7 a DTDFvocab:TimeScale  .
		OPTIONAL {?c7 ?attribute ?value}
	}",

	"characteristic_multiplicity": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c8 a DTDFvocab:Multiplicity  .
		OPTIONAL {?c8 ?attribute ?value}
	}",

	"characteristic_life_cycle_stage": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c9 a DTDFvocab:LifeCycleStage  .
		OPTIONAL {?c9 ?attribute ?value}
	}",

	"characteristic_constellation": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c12 a DTDFvocab:Constellation  .
		OPTIONAL {?c12 ?attribute ?value}
	}",

	"characteristic_evolution_stage": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c13 a DTDFvocab:EvolutionStage  .
		OPTIONAL {?c13 ?attribute ?value}
	}",

	"characteristic_fidelity_consideration": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c14 a DTDFvocab:FidelityConsideration  .
		OPTIONAL {?c14 ?attribute ?value}
	}",

	"characteristic_technical_connection": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c15 a DTDFvocab:TechnicalConnection  .
		OPTIONAL {?c15 ?attribute ?value}
	}",

	"characteristic_deployment": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c16 a DTDFvocab:Deployment  .
		OPTIONAL {?c16 ?attribute ?value}
	}",

	"characteristic_horizontal_integration": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c18 a DTDFvocab:HoriIntegration  .
		OPTIONAL {?c18 ?attribute ?value}
	}",

	"characteristic_data_ownership": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c19 a DTDFvocab:DataOwnershipPrivacy  .
		OPTIONAL {?c19 ?attribute ?value}
	}",

	"characteristic_standardization": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c20 a DTDFvocab:Standardization  .
		OPTIONAL {?c20 ?attribute ?value}
	}",

	"characteristic_security_safety": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c21 a DTDFvocab:SecuritySafety  .
		OPTIONAL {?c21 ?attribute ?value}
	}",
}
