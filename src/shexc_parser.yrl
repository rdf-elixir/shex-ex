%% Grammar for ShExC as specified in http://shex.io/shex-semantics/index.html#shexc

Nonterminals shexDoc directives directive statements statement
  prefixDecl baseDecl importDecl notStartAction startActions start shapeExprDecl
  shapeExpression shapeOr shapeAnd shapeNot shapeOrSeq shapeAndSeq shapeOrSeqBegin shapeAndSeqBegin
  inlineShapeExpression inlineShapeOr inlineShapeAnd inlineShapeOrSeq inlineShapeAndSeq inlineShapeOrSeqBegin inlineShapeAndSeqBegin inlineShapeNot
	shapeAtom inlineShapeAtom shapeExprLabel shapeRef shapeOrRef inlineShapeOrRef
	litNodeConstraint nonLitNodeConstraint nonLiteralKind
	xsFacets xsFacet stringFacets stringFacet stringLength numericFacets numericFacet numericRange numericLength
	shapeDefinition inlineShapeDefinition extraPropertySetSeq extraPropertySet predicates
	tripleExpression oneOfTripleExpr multiElementOneOf groupTripleExprSeq groupTripleExpr
	singleElementGroup multiElementGroup unaryTripleExprSeq unaryTripleExpr bracketedTripleExpr
	tripleConstraint cardinality senseFlags
	valueSet valueSetValues valueSetValue iriRange iriExclusions iriExclusion
	literalRange literalExclusions literalExclusion languageRange languageExclusions languageExclusion
	include annotations annotation semanticActions codeDecls codeDecl
	literal datatype tripleExprLabel

  predicate numericLiteral rdfLiteral booleanLiteral iri prefixedName blankNode.

Terminals prefix_ns prefix_ln at_prefix_ns at_prefix_ln iriref blank_node_label code regexp regexp_flags
  string_literal_quote lang_string_literal_quote langtag integer decimal double boolean repeat_range
  '.' ';' '[' ']' '(' ')' '{' '}' '^^' '^' '=' '@' '$' '|' '&' '?' '*' '+' '-' '~' '//' '%'
  'AND' 'OR' 'NOT' 'PREFIX' 'BASE' 'IMPORT' 'START' 'EXTERNAL'
  'LITERAL' 'IRI' 'BNODE' 'NONLITERAL' 'LENGTH' 'MINLENGTH' 'MAXLENGTH'
	'MININCLUSIVE' 'MINEXCLUSIVE' 'MAXINCLUSIVE' 'MAXEXCLUSIVE' 'TOTALDIGITS' 'FRACTIONDIGITS'
	'CLOSED' 'EXTRA' .


Rootsymbol shexDoc.

shexDoc -> '$empty' 														: {shex_doc, []  , nil , []} .
shexDoc -> directives notStartAction statements : {shex_doc, '$1', nil , ['$2' | '$3']} .
shexDoc -> directives startActions statements 	: {shex_doc, '$1', '$2', '$3'} .
shexDoc -> directives notStartAction 						: {shex_doc, '$1', nil , ['$2']} .
shexDoc -> directives startActions 							: {shex_doc, '$1', '$2', []} .
shexDoc -> directives 													: {shex_doc, '$1', nil , []} .
shexDoc -> notStartAction statements 						: {shex_doc, []  , nil , ['$1' | '$2']} .
shexDoc -> startActions statements 							: {shex_doc, []  , '$1', '$2'} .
shexDoc -> notStartAction 											: {shex_doc, []  , nil , ['$1']} .
shexDoc -> startActions 												: {shex_doc, []  , '$1', []} .

directives -> directive : ['$1'] .
directives -> directive directives : ['$1' | '$2'] .
directive -> prefixDecl     : '$1' .
directive -> baseDecl       : '$1' .
directive -> importDecl     : '$1' .

prefixDecl  -> 'PREFIX' prefix_ns iriref      : {prefix, '$2', to_iri_string('$3')} .
baseDecl    -> 'BASE' iriref                  : {base, to_iri_string('$2')} .
importDecl  -> 'IMPORT' iriref                : {import, to_iri_string('$2')} .

notStartAction -> start : '$1' .
notStartAction -> shapeExprDecl : '$1' .

start -> 'START' '=' inlineShapeExpression : {start, '$3'} .

startActions -> codeDecls : {start_actions, '$1'} .

statements -> statement : ['$1'] .
statements -> statement statements : ['$1' | '$2'] .
statement -> directive       : '$1' .
statement -> notStartAction  : '$1' .


shapeExprDecl -> shapeExprLabel shapeExpression : {shape_expr_decl, '$1', '$2'} .
shapeExprDecl -> shapeExprLabel 'EXTERNAL' : {shape_expr_decl, '$1', external} .

shapeExpression -> shapeOr : '$1' .
inlineShapeExpression -> inlineShapeOr : '$1' .

shapeOr -> shapeAnd : '$1' .
shapeOr -> shapeOrSeqBegin : '$1' .
shapeOrSeqBegin -> shapeAnd 'OR' shapeOrSeq : {shape_or, ['$1' | '$3']} .
shapeOrSeq -> shapeAnd 'OR' shapeOrSeq : ['$1' | '$3'] .
shapeOrSeq -> shapeAnd : ['$1'] .

inlineShapeOr -> inlineShapeAnd : '$1' .
inlineShapeOr -> inlineShapeOrSeqBegin : '$1' .
inlineShapeOrSeqBegin -> inlineShapeAnd 'OR' inlineShapeOrSeq : {shape_or, ['$1' | '$3']} .
inlineShapeOrSeq -> inlineShapeAnd 'OR' inlineShapeOrSeq : ['$1' | '$3'] .
inlineShapeOrSeq -> inlineShapeAnd : ['$1'] .

shapeAnd -> shapeNot : '$1' .
shapeAnd -> shapeAndSeqBegin : '$1' .
shapeAndSeqBegin -> shapeNot 'AND' shapeAndSeq : {shape_and, ['$1' | '$3']} .
shapeAndSeq -> shapeNot 'AND' shapeAndSeq : ['$1' | '$3'] .
shapeAndSeq -> shapeNot : ['$1'] .

inlineShapeAnd -> inlineShapeNot : '$1' .
inlineShapeAnd -> inlineShapeAndSeqBegin : '$1' .
inlineShapeAndSeqBegin -> inlineShapeNot 'AND' inlineShapeAndSeq : {shape_and, ['$1' | '$3']} .
inlineShapeAndSeq -> inlineShapeNot 'AND' inlineShapeAndSeq : ['$1' | '$3'] .
inlineShapeAndSeq -> inlineShapeNot : ['$1'] .

shapeNot -> shapeAtom : '$1' .
shapeNot -> 'NOT' shapeAtom : {shape_not, '$2'} .

inlineShapeNot -> inlineShapeAtom : '$1' .
inlineShapeNot -> 'NOT' inlineShapeAtom : {shape_not, '$2'} .


shapeAtom -> nonLitNodeConstraint : '$1' .
shapeAtom -> nonLitNodeConstraint shapeOrRef : {shape_and, ['$1', '$2']} .
shapeAtom -> litNodeConstraint : '$1' .
shapeAtom -> shapeOrRef : '$1' .
shapeAtom -> shapeOrRef nonLitNodeConstraint : {shape_and, ['$1', '$2']} .
shapeAtom -> '(' shapeExpression ')' : '$2' .
shapeAtom -> '.' : empty_shape .

inlineShapeAtom -> nonLitNodeConstraint : '$1'.
inlineShapeAtom -> nonLitNodeConstraint inlineShapeOrRef : {shape_and, ['$1', '$2']} .
inlineShapeAtom -> litNodeConstraint : '$1' .
inlineShapeAtom -> inlineShapeOrRef : '$1' .
inlineShapeAtom -> inlineShapeOrRef nonLitNodeConstraint : {shape_and, ['$1', '$2']} .
inlineShapeAtom -> '(' shapeExpression ')' : '$2' .
inlineShapeAtom -> '.' : empty_shape .

shapeOrRef -> shapeDefinition : '$1' .
shapeOrRef ->  shapeRef : '$1' .
inlineShapeOrRef -> inlineShapeDefinition : '$1' .
inlineShapeOrRef -> shapeRef : '$1' .
shapeRef -> at_prefix_ln       : {shape_ref, '$1'} .
shapeRef -> at_prefix_ns       : {shape_ref, '$1'} .
shapeRef -> '@' shapeExprLabel : {shape_ref, '$2'} .

litNodeConstraint -> 'LITERAL' xsFacets : {literal_node_constraint, literal, nil , nil , '$2' } .
litNodeConstraint -> 'LITERAL' 					: {literal_node_constraint, literal, nil , nil , nil  } .
litNodeConstraint -> datatype   				: {literal_node_constraint, nil    , '$1', nil , nil  } .
litNodeConstraint -> datatype xsFacets  : {literal_node_constraint, nil    , '$1', nil , '$2' } .
litNodeConstraint -> valueSet  					: {literal_node_constraint, nil    , nil , '$1', nil  } .
litNodeConstraint -> valueSet xsFacets  : {literal_node_constraint, nil    , nil , '$1', '$2' } .
litNodeConstraint -> numericFacets 			: {literal_node_constraint, nil    , nil , nil , '$1' } .

nonLitNodeConstraint -> nonLiteralKind  						: {non_literal_node_constraint, '$1', nil } .
nonLitNodeConstraint -> nonLiteralKind stringFacets : {non_literal_node_constraint, '$1', '$2' } .
nonLitNodeConstraint -> stringFacets 								: {non_literal_node_constraint, nil , '$1' } .

nonLiteralKind -> 'IRI'        : iri .
nonLiteralKind -> 'BNODE'      : bnode .
nonLiteralKind -> 'NONLITERAL' : nonliteral .

xsFacets -> xsFacet : ['$1'] .
xsFacets -> xsFacet xsFacets : ['$1' | '$2'] .

xsFacet -> stringFacet : '$1' .
xsFacet -> numericFacet : '$1' .

stringFacets -> stringFacet : ['$1'].
stringFacets -> stringFacet stringFacets : ['$1' | '$2'] .

stringFacet -> stringLength integer : {string_facet, '$1', '$2'} .
stringFacet -> regexp               : {string_facet, regexp, {'$1', nil}} .
stringFacet -> regexp regexp_flags  : {string_facet, regexp, {'$1', '$2'}} .
stringLength -> 'LENGTH'    : length .
stringLength -> 'MINLENGTH' : minlength .
stringLength -> 'MAXLENGTH' : maxlength .

numericFacets -> numericFacet : ['$1'] .
numericFacets -> numericFacet numericFacets : ['$1' | '$2'] .

numericFacet -> numericRange numericLiteral : {numeric_range_facet, '$1', '$2'} .
numericFacet -> numericLength integer : {numeric_length_facet, '$1', '$2'} .
numericRange -> 'MININCLUSIVE' : mininclusive .
numericRange -> 'MINEXCLUSIVE' : minexclusive .
numericRange -> 'MAXINCLUSIVE' : maxinclusive .
numericRange -> 'MAXEXCLUSIVE' : maxexclusive .
numericLength -> 'TOTALDIGITS' : totaldigits .
numericLength -> 'FRACTIONDIGITS' : fractiondigits .

shapeDefinition -> extraPropertySetSeq '{' tripleExpression '}' annotations semanticActions : {shape, '$1', '$3', '$5', '$6'} .
shapeDefinition -> extraPropertySetSeq '{' '}' annotations semanticActions                  : {shape, '$1', nil , '$4', '$5'} .
shapeDefinition -> extraPropertySetSeq '{' tripleExpression '}' semanticActions             : {shape, '$1', '$3', nil , '$5'} .
shapeDefinition -> extraPropertySetSeq '{' '}' semanticActions                              : {shape, '$1', nil , nil , '$4'} .
shapeDefinition -> '{' tripleExpression '}' annotations semanticActions : {shape, nil, '$2', '$4', '$5'} .
shapeDefinition -> '{' '}' annotations semanticActions                  : {shape, nil, nil , '$3', '$4'} .
shapeDefinition -> '{' tripleExpression '}' semanticActions             : {shape, nil, '$2', nil , '$4'} .
shapeDefinition -> '{' '}' semanticActions                              : {shape, nil, nil , nil , '$3'} .

inlineShapeDefinition -> extraPropertySetSeq '{' tripleExpression '}' : {shape, '$1', '$3', nil, nil} .
inlineShapeDefinition -> extraPropertySetSeq '{' '}'                  : {shape, '$1', nil , nil, nil} .
inlineShapeDefinition -> '{' tripleExpression '}'                     : {shape, nil , '$2', nil , nil} .
inlineShapeDefinition -> '{' '}'                                      : {shape, nil , nil , nil , nil} .

extraPropertySetSeq -> extraPropertySet : ['$1'] .
extraPropertySetSeq -> 'CLOSED' : [closed] .
extraPropertySetSeq -> extraPropertySet extraPropertySetSeq : ['$1' | '$2'] .
extraPropertySetSeq -> 'CLOSED' extraPropertySetSeq : [closed | '$2'] .

extraPropertySet -> 'EXTRA' predicates : {extra, '$2'} .

predicates -> predicate : ['$1'] .
predicates -> predicate predicates : ['$1' | '$2'] .

tripleExpression  -> oneOfTripleExpr : '$1' .
oneOfTripleExpr   -> groupTripleExpr : '$1' .
oneOfTripleExpr   -> multiElementOneOf : '$1' .
multiElementOneOf -> groupTripleExpr groupTripleExprSeq : {one_of, ['$1' | '$2']} .

groupTripleExprSeq -> '|' groupTripleExpr : ['$2'] .
groupTripleExprSeq -> '|' groupTripleExpr groupTripleExprSeq : ['$2' | '$3'] .

groupTripleExpr    -> singleElementGroup  : '$1' .
groupTripleExpr    -> multiElementGroup   : '$1' .
singleElementGroup -> unaryTripleExpr ';' : '$1' .
singleElementGroup -> unaryTripleExpr     : '$1' .
multiElementGroup  -> unaryTripleExpr unaryTripleExprSeq : {each_of, ['$1' | '$2']} .

unaryTripleExprSeq -> ';' unaryTripleExpr ';' : ['$2'] .
unaryTripleExprSeq -> ';' unaryTripleExpr : ['$2'] .
unaryTripleExprSeq -> ';' unaryTripleExpr unaryTripleExprSeq : ['$2' | '$3'] .

unaryTripleExpr -> '$' tripleExprLabel tripleConstraint    : {named_triple_expression, '$2', '$3'} .
unaryTripleExpr -> '$' tripleExprLabel bracketedTripleExpr : {named_triple_expression, '$2', '$3'} .
unaryTripleExpr -> tripleConstraint : '$1' .
unaryTripleExpr -> bracketedTripleExpr : '$1' .
unaryTripleExpr -> include : '$1' .

bracketedTripleExpr -> '(' tripleExpression ')' cardinality annotations semanticActions : {bracketed_triple_expr, '$2', '$4', '$5', '$6'} .
bracketedTripleExpr -> '(' tripleExpression ')' annotations semanticActions             : {bracketed_triple_expr, '$2', nil , '$4', '$5'} .
bracketedTripleExpr -> '(' tripleExpression ')' cardinality semanticActions             : {bracketed_triple_expr, '$2', '$4', nil , '$5'} .
bracketedTripleExpr -> '(' tripleExpression ')' semanticActions							            : {bracketed_triple_expr, '$2', nil , nil , '$4'} .

tripleConstraint -> senseFlags predicate inlineShapeExpression cardinality annotations semanticActions : {triple_constraint, '$1', '$2', '$3', '$4', '$5', '$6'} .
tripleConstraint -> senseFlags predicate inlineShapeExpression annotations semanticActions						 : {triple_constraint, '$1', '$2', '$3', nil , '$4', '$5'} .
tripleConstraint -> predicate inlineShapeExpression cardinality annotations semanticActions						 : {triple_constraint, nil , '$1', '$2', '$3', '$4', '$5'} .
tripleConstraint -> predicate inlineShapeExpression annotations semanticActions												 : {triple_constraint, nil , '$1', '$2', nil , '$3', '$4'} .
tripleConstraint -> senseFlags predicate inlineShapeExpression cardinality semanticActions						 : {triple_constraint, '$1', '$2', '$3', '$4', nil , '$5'} .
tripleConstraint -> senseFlags predicate inlineShapeExpression semanticActions												 : {triple_constraint, '$1', '$2', '$3', nil , nil , '$4'} .
tripleConstraint -> predicate inlineShapeExpression cardinality semanticActions												 : {triple_constraint, nil , '$1', '$2', '$3', nil , '$4'} .
tripleConstraint -> predicate inlineShapeExpression semanticActions																		 : {triple_constraint, nil , '$1', '$2', nil , nil , '$3'} .

cardinality -> '*' : '*' .
cardinality -> '+' : '+' .
cardinality -> '?' : '?' .
cardinality -> repeat_range : '$1' .

senseFlags -> '^' : inverse .

valueSet -> '[' valueSetValues ']' : {value_set, '$2'} .
valueSet -> '[' ']'                : {value_set, []} .
valueSetValues -> valueSetValue : ['$1'] .
valueSetValues -> valueSetValue valueSetValues : ['$1' | '$2'] .
valueSetValue -> iriRange : '$1' .
valueSetValue -> literalRange : '$1' .
valueSetValue -> languageRange : '$1' .
valueSetValue -> '.' iriExclusions 			: {exclusions, '$2'} .
valueSetValue -> '.' literalExclusions 	: {exclusions, '$2'} .
valueSetValue -> '.' languageExclusions : {exclusions, '$2'} .

iriRange -> iri '~' iriExclusions : {iri_range, '$1', stem, '$3'} .
iriRange -> iri '~'						    : {iri_range, '$1', stem, nil } .
iriRange -> iri								    : {iri_range, '$1', nil , nil } .

iriExclusions -> iriExclusion : ['$1'] .
iriExclusions -> iriExclusion iriExclusions : ['$1' | '$2'] .
iriExclusion -> '-' iri '~' : {iri_exclusion, '$2', stem} .
iriExclusion -> '-' iri			: {iri_exclusion, '$2', nil } .

literalRange -> literal '~' literalExclusions : {literal_range, '$1', stem, '$3'} .
literalRange -> literal '~'						        : {literal_range, '$1', stem, nil } .
literalRange -> literal								        : {literal_range, '$1', nil , nil } .

literalExclusions -> literalExclusion : ['$1'] .
literalExclusions -> literalExclusion literalExclusions : ['$1' | '$2'] .
literalExclusion -> '-' literal '~' : {literal_exclusion, '$2', stem} .
literalExclusion -> '-' literal     : {literal_exclusion, '$2', nil } .

languageRange -> langtag '~' languageExclusions : {language_range, '$1', stem, '$3'} .
languageRange -> langtag '~'										: {language_range, '$1', stem, nil } .
languageRange -> langtag 												: {language_range, '$1', nil , nil } .
languageRange -> '@' '~' languageExclusions 		: {language_range, '$1', stem, '$3'} .
languageRange -> '@' '~' 												: {language_range, '$1', stem, nil } .

languageExclusions -> languageExclusion : ['$1'] .
languageExclusions -> languageExclusion languageExclusions : ['$1' | '$2'] .
languageExclusion -> '-' langtag '~' : {language_exclusion, '$2', stem} .
languageExclusion -> '-' langtag     : {language_exclusion, '$2', nil } .

include -> '&' tripleExprLabel : {include, '$2'} .

annotations -> annotation : ['$1'] .
annotations -> annotation annotations : ['$1' | '$2'] .
annotation -> '//' predicate iri     : {annotation, '$2', '$3'} .
annotation -> '//' predicate literal : {annotation, '$2', '$3'} .

semanticActions -> '$empty' : nil .
semanticActions -> codeDecls : {code_decls, '$1'} .
codeDecls -> codeDecl : ['$1'] .
codeDecls -> codeDecl codeDecls : ['$1' | '$2'] .
codeDecl -> '%' iri code : {code_decl, '$2', '$3'} .
codeDecl -> '%' iri '%'  : {code_decl, '$2', nil} .


literal -> rdfLiteral     : '$1' .
literal -> numericLiteral : '$1' .
literal -> booleanLiteral : '$1' .

predicate -> iri : '$1' .

datatype -> iri : '$1' .

shapeExprLabel -> iri : '$1' .
shapeExprLabel -> blankNode : '$1' .

tripleExprLabel -> iri : '$1' .
tripleExprLabel -> blankNode : '$1' .

rdfLiteral -> string_literal_quote '^^' datatype : to_literal('$1', {datatype, '$3'}) .
rdfLiteral -> string_literal_quote               : to_literal('$1') .
rdfLiteral -> lang_string_literal_quote          : to_lang_literal('$1') .

numericLiteral -> integer : to_literal('$1') .
numericLiteral -> decimal : to_literal('$1') .
numericLiteral -> double  : to_literal('$1') .

booleanLiteral -> boolean : to_literal('$1') .

iri -> iriref       : to_iri('$1') .
iri -> prefixedName : '$1' .

prefixedName -> prefix_ln : '$1' .
prefixedName -> prefix_ns : '$1' .

blankNode -> blank_node_label : to_bnode('$1') .



Erlang code.

to_iri_string(IRIREF) -> 'Elixir.RDF.Serialization.ParseHelper':to_iri_string(IRIREF) .
to_iri(IRIREF) -> 'Elixir.RDF.Serialization.ParseHelper':to_absolute_or_relative_iri(IRIREF) .
to_bnode(BLANK_NODE) -> 'Elixir.RDF.Serialization.ParseHelper':to_bnode(BLANK_NODE).
to_literal(STRING_LITERAL_QUOTE) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE).
to_literal(STRING_LITERAL_QUOTE, Type) -> 'Elixir.RDF.Serialization.ParseHelper':to_literal(STRING_LITERAL_QUOTE, Type).
to_lang_literal(STRING_LITERAL_QUOTE) -> 'Elixir.ShEx.ShExC.ParseHelper':to_lang_literal(STRING_LITERAL_QUOTE).
