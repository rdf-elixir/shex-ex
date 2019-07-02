%% Grammar for ShapeMaps as specified in https://shexspec.github.io/shape-map/#grammar

Nonterminals
	shapeMap shapeAssociations shapeAssociation nodeSpec shapeSpec
	triplePattern subjectTerm predicate objectTerm iri blankNode literal
	rdfLiteral numericLiteral booleanLiteral .

Terminals
	iriref blank_node_label rdf_type at_start
	string_literal_quote lang_string_literal_quote integer decimal double boolean
	'_' ',' '{' '}' '^^' '@' 'START' 'FOCUS' .


Rootsymbol shapeMap.

shapeMap -> shapeAssociations : '$1' .

shapeAssociations -> shapeAssociation ',' shapeAssociations : ['$1' | '$3'] .
shapeAssociations -> shapeAssociation : ['$1'] .

shapeAssociation -> nodeSpec shapeSpec : {'$1', '$2'} .
nodeSpec -> objectTerm : {node, '$1'} .
nodeSpec -> triplePattern : {triple_pattern, '$1'} .

subjectTerm -> iri : '$1' .
subjectTerm -> blankNode : '$1' .
objectTerm -> subjectTerm : '$1' .
objectTerm -> literal : '$1' .

triplePattern -> '{' 'FOCUS' predicate objectTerm '}'  : {focus, '$3', '$4'} .
triplePattern -> '{' 'FOCUS' predicate '_' '}'         : {focus, '$3', '_' } .
triplePattern -> '{' subjectTerm predicate 'FOCUS' '}' : {'$2', '$3', focus} .
triplePattern -> '{' '_' predicate 'FOCUS' '}'         : {'_'   , '$3', focus} .

shapeSpec -> '@' iri     : '$2' .
shapeSpec -> '@' 'START' : start.
shapeSpec -> at_start    : start.

literal -> rdfLiteral     : '$1' .
literal -> numericLiteral : '$1' .
literal -> booleanLiteral : '$1' .

rdfLiteral -> string_literal_quote '^^' iri : to_literal('$1', {datatype, '$3'}) .
rdfLiteral -> string_literal_quote          : to_literal('$1') .
rdfLiteral -> lang_string_literal_quote     : to_lang_literal('$1') .
numericLiteral -> integer : to_literal('$1') .
numericLiteral -> decimal : to_literal('$1') .
numericLiteral -> double  : to_literal('$1') .
booleanLiteral -> boolean : to_literal('$1') .

predicate -> iri : '$1' .
predicate -> rdf_type : rdf_type .

iri -> iriref : to_iri('$1') .
blankNode -> blank_node_label : to_bnode('$1') .


Erlang code.

to_iri(IRIREF) -> 'Elixir.RDF.Serialization.ParseHelper':to_absolute_or_relative_iri(IRIREF) .
to_bnode(BLANK_NODE) -> 'Elixir.RDF.Serialization.ParseHelper':to_bnode(BLANK_NODE).
to_literal(STRING_LITERAL_QUOTE) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE).
to_literal(STRING_LITERAL_QUOTE, Type) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE, Type).
to_lang_literal(STRING_LITERAL_QUOTE) -> 'Elixir.ShEx.ShExC.ParseHelper':to_lang_literal(STRING_LITERAL_QUOTE).
