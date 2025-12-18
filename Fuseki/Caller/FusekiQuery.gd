extends Node

#Sparql queries intended to interact with the Fuseki Server

const QUERIES = {
#Dt/PT objects -------------------------------------------------------------------------------------
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
#Rabbit objects ------------------------------------------------------------------------------------
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
#Characteristics ------------------------------------------------------------------------------------
"c1": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c1 a DTDFvocab:SystemUnderStudy  .
		OPTIONAL {?c1 ?attribute ?value}
	}",
"c2": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c2 a DTDFvocab:ActingComponent  .
		OPTIONAL {?c2 ?attribute ?value}
	}",
"c4": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c4 a DTDFvocab:DataTransmitted  .
		OPTIONAL {?c4 ?attribute ?value}
	}",
"c5": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c5 a DTDFvocab:VirtualToPhysical  .
		OPTIONAL {?c5 ?attribute ?value}
	}",
"c7": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c7 a DTDFvocab:TimeScale  .
		OPTIONAL {?c7 ?attribute ?value}
	}",
"c8": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c8 a DTDFvocab:Multiplicity  .
		OPTIONAL {?c8 ?attribute ?value}
	}",
"c9": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c9 a DTDFvocab:LifeCycleStage  .
		OPTIONAL {?c9 ?attribute ?value}
	}",
"c12": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c12 a DTDFvocab:Constellation  .
		OPTIONAL {?c12 ?attribute ?value}
	}",
"c13": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c13 a DTDFvocab:EvolutionStage  .
		OPTIONAL {?c13 ?attribute ?value}
	}",
"c14": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c14 a DTDFvocab:FidelityConsideration  .
		OPTIONAL {?c14 ?attribute ?value}
	}",
"c15": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c15 a DTDFvocab:TechnicalConnection  .
		OPTIONAL {?c15 ?attribute ?value}
	}",
"c16": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c16 a DTDFvocab:Deployment  .
		OPTIONAL {?c16 ?attribute ?value}
	}",
"c18": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c18 a DTDFvocab:HoriIntegration  .
		OPTIONAL {?c18 ?attribute ?value}
	}",
"c19": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c19 a DTDFvocab:DataOwnershipPrivacy  .
		OPTIONAL {?c19 ?attribute ?value}
	}",
"c20": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c20 a DTDFvocab:Standardization  .
		OPTIONAL {?c20 ?attribute ?value}
	}",
"c21": "PREFIX DTDFvocab: <https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>
	PREFIX rdfs:        <http://www.w3.org/2000/01/rdf-schema#>
	PREFIX base:        <https://bentleyjoakes.github.io/DTDF/vocab/base#>

	SELECT *
	WHERE {
		?c21 a DTDFvocab:SecuritySafety  .
		OPTIONAL {?c21 ?attribute ?value}
	}",
}
