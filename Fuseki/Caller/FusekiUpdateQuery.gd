## Utility class for building SPARQL UPDATE strings.
##
## Generates INSERT DATA, DELETE DATA, DELETE/INSERT WHERE, and full-entity
## DELETE WHERE operations.  Reuses the ontology prefixes defined in
## [FusekiQuery] so short prefixed names (e.g. DTDFvocab:MyService) work
## out of the box.
##
## Prefix names are normalized automatically, so both "DTDFVocab:Service"
## and "DTDFvocab:Service" resolve correctly.
##
## All methods are static — no instantiation required.
class_name FusekiUpdateQuery


# ── Prefix block ─────────────────────────────────────────────────────────────
## Static vocabulary prefixes — these are standard and don't change per dataset.
const STATIC_PREFIXES := {
	"DTDFvocab": "<https://bentleyjoakes.github.io/DTDF/vocab/DTDFVocab#>",
	"rdfs": "<http://www.w3.org/2000/01/rdf-schema#>",
	"base": "<https://bentleyjoakes.github.io/DTDF/vocab/base#>",
	"rabbit": "<https://bentleyjoakes.github.io/DTaaS/RabbitMQVocab#>"
}


## Returns all prefixes: static vocabulary + dynamic graph-derived.
static func _all_prefixes() -> Dictionary:
	var result := STATIC_PREFIXES.duplicate()
	result.merge(FusekiConfig.GRAPH_PREFIXES)
	return result


## Returns the standard PREFIX declarations as a single string block,
## including dynamically discovered graph prefixes.
static func _prefix_block() -> String:
	var lines := PackedStringArray()
	var all := _all_prefixes()
	for key in all:
		lines.append("PREFIX %s: %s" % [key, all[key]])
	return "\n".join(lines)

## Maps lowercase prefix names to their canonical form used in PREFIX
## declarations.  This lets callers write "DTDFVocab:Service" even though
## the declared prefix is "DTDFvocab".
## Rebuilt dynamically to include graph-derived prefixes.
static func _get_canonical_map() -> Dictionary:
	var result := {}
	var all := _all_prefixes()
	for key in all:
		result[key.to_lower()] = key
	return result


## Normalizes the prefix portion of a prefixed name so it matches the
## canonical form used in PREFIX declarations.
## e.g. "DTDFVocab:Service" → "DTDFvocab:Service"
## Full URIs (<...>) and non-prefixed names are returned unchanged.
static func _normalize_term(term: String) -> String:
	if term.begins_with("<") or ":" not in term:
		return term
	var colon_pos := term.find(":")
	var prefix := term.substr(0, colon_pos)
	var local := term.substr(colon_pos + 1)
	var canonical: String = _get_canonical_map().get(prefix.to_lower(), prefix)
	return "%s:%s" % [canonical, local]


## Wraps [param value] as a SPARQL term.
## If [param is_literal] is true the value is quoted; otherwise it is used
## as-is (assumed to be a prefixed name or full URI).
static func _format_object(value: String, is_literal: bool) -> String:
	if is_literal:
		# Escape internal double-quotes and backslashes for safety.
		var escaped := value.replace("\\", "\\\\").replace("\"", "\\\"")
		return "\"%s\"" % escaped
	return _normalize_term(value)


# ── Public API ────────────────────────────────────────────────────────────────

## Returns the full GRAPH URI wrapper for a given prefix.
static func _graph_uri(graph_prefix: String) -> String:
	assert(graph_prefix != "", "A target graph prefix must be specified for write operations.")
	var full_uri: String = FusekiConfig.GRAPH_PREFIXES.get(graph_prefix, "")
	if full_uri == "":
		printerr("FusekiUpdateQuery: Warning: Graph prefix '", graph_prefix, "' not found in discovered graphs.")
		# Fallback: assume the prefix itself might be a full URI if misconfigured, or just wrap it
		return "<%s>" % graph_prefix
	
	# Strip the trailing #> and just return <...>
	var clean_uri = full_uri.substr(0, full_uri.length() - 2) + ">"
	return clean_uri


## Builds an INSERT DATA statement that adds a single triple.
##
## [param graph_prefix] The prefix of the target named graph.
## [param subject]      Prefixed name or full URI of the subject.
## [param predicate]    Prefixed name or full URI of the predicate.
## [param object]       The object value.
## [param is_literal]   If true, [param object] is wrapped in quotes.
static func build_insert(
	graph_prefix: String,
	subject: String,
	predicate: String,
	object: String,
	is_literal: bool = true
) -> String:
	return "%s\n\nINSERT DATA {\n\tGRAPH %s {\n\t\t%s %s %s .\n\t}\n}" % [
		_prefix_block(),
		_graph_uri(graph_prefix),
		_normalize_term(subject),
		_normalize_term(predicate),
		_format_object(object, is_literal)
	]


## Builds a DELETE DATA statement that removes a single specific triple.
static func build_delete(
	graph_prefix: String,
	subject: String,
	predicate: String,
	object: String,
	is_literal: bool = true
) -> String:
	return "%s\n\nDELETE DATA {\n\tGRAPH %s {\n\t\t%s %s %s .\n\t}\n}" % [
		_prefix_block(),
		_graph_uri(graph_prefix),
		_normalize_term(subject),
		_normalize_term(predicate),
		_format_object(object, is_literal)
	]


## Builds a DELETE/INSERT WHERE that atomically replaces one object value
## with another for a given subject + predicate.
static func build_update(
	graph_prefix: String,
	subject: String,
	predicate: String,
	old_value: String,
	new_value: String,
	is_literal: bool = true
) -> String:
	var s := _normalize_term(subject)
	var p := _normalize_term(predicate)
	var old_obj := _format_object(old_value, is_literal)
	var new_obj := _format_object(new_value, is_literal)
	var g := _graph_uri(graph_prefix)
	return "%s\n\nDELETE {\n\tGRAPH %s { %s %s %s . }\n}\nINSERT {\n\tGRAPH %s { %s %s %s . }\n}\nWHERE {\n\tGRAPH %s { %s %s %s . }\n}" % [
		_prefix_block(), g, s, p, old_obj, g, s, p, new_obj, g, s, p, old_obj
	]


## Builds a DELETE WHERE that removes *all* triples where [param subject]
## is the subject — effectively deleting the entity.
static func build_delete_entity(graph_prefix: String, subject: String) -> String:
	var g := _graph_uri(graph_prefix)
	return "%s\n\nDELETE WHERE {\n\tGRAPH %s {\n\t\t%s ?p ?o .\n\t}\n}" % [
		_prefix_block(), g, _normalize_term(subject)
	]
