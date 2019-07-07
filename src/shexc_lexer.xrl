%% \00=NULL
%% \01-\x1F=control codes
%% \x20=space

Definitions.

COMMENT = #[^\n\r]*|\/\*([^*]|\*(\/|[^/]))*\*\/
PASSED_TOKENS	= [\s\t\n\r]+|{COMMENT}

HEX           = ([0-9]|[A-F]|[a-f])
UCHAR         = (\\u({HEX})({HEX})({HEX})({HEX}))|(\\U({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX})({HEX}))
ECHAR         = \\[tbnrf"'\\]
PERCENT	      =	(%{HEX}{HEX})
PN_CHARS_BASE = ([A-Z]|[a-z]|[\x{00C0}-\x{00D6}]|[\x{00D8}-\x{00F6}]|[\x{00F8}-\x{02FF}]|[\x{0370}-\x{037D}]|[\x{037F}-\x{1FFF}]|[\x{200C}-\x{200D}]|[\x{2070}-\x{218F}]|[\x{2C00}-\x{2FEF}]|[\x{3001}-\x{D7FF}]|[\x{F900}-\x{FDCF}]|[\x{FDF0}-\x{FFFD}]|[\x{10000}-\x{EFFFF}])
PN_CHARS_U    = ({PN_CHARS_BASE}|_)
PN_CHARS      = ({PN_CHARS_U}|-|[0-9]|\x{00B7}|[\x{0300}-\x{036F}]|[\x{203F}-\x{2040}])
PN_PREFIX	    =	({PN_CHARS_BASE}(({PN_CHARS}|\.)*{PN_CHARS})?)
PN_LOCAL_ESC  =	\\(_|~|\.|\-|\!|\$|\&|\'|\(|\)|\*|\+|\,|\;|\=|\/|\?|\#|\@|\%)
PLX           =	({PERCENT}|{PN_LOCAL_ESC})
PN_LOCAL	    =	({PN_CHARS_U}|:|[0-9]|{PLX})(({PN_CHARS}|\.|:|{PLX})*({PN_CHARS}|:|{PLX}))?

PNAME_NS	    =	{PN_PREFIX}?:
PNAME_LN	    =	{PNAME_NS}{PN_LOCAL}

ATPNAME_NS = @{PNAME_NS}
ATPNAME_LN = @{PNAME_LN}

EXPONENT	=	([eE][+-]?[0-9]+)
BOOLEAN   = true|false
INTEGER	  =	[+-]?[0-9]+
DECIMAL	  =	[+-]?[0-9]*\.[0-9]+
DOUBLE	  =	[+-]?([0-9]+\.[0-9]*{EXPONENT}|\.?[0-9]+{EXPONENT})

REGEXP = \/([^/\n\r\\]|\\[/nrt\\|.?*+(){}\[\]$^-]|{UCHAR})+\/
REGEXP_FLAGS = [smix]+

REPEAT_RANGE = \{{INTEGER}(,({INTEGER}|\*)?)?\}

LANGTAG	=	@[a-zA-Z]+(-[a-zA-Z0-9]+)*

CODE = \{([^%\\]|\\[%\\]|{UCHAR})*%\}

IRIREF = <([^\x00-\x20<>"{}|^`\\]|{UCHAR})*>
BLANK_NODE_LABEL = _:({PN_CHARS_U}|[0-9])(({PN_CHARS}|\.)*({PN_CHARS}))?
STRING_LITERAL_1           = "([^"\\\n\r]|{ECHAR}|{UCHAR})*"
STRING_LITERAL_2           =	'([^'\\\n\r]|{ECHAR}|{UCHAR})*'
STRING_LITERAL_LONG1	     =	'''(('|'')?([^'\\]|{ECHAR}|{UCHAR}))*'''
STRING_LITERAL_LONG2	     =	"""(("|"")?([^"\\]|{ECHAR}|{UCHAR}))*"""
LANG_STRING_LITERAL_1      = "([^"\\\n\r]|{ECHAR}|{UCHAR})*"{LANGTAG}
LANG_STRING_LITERAL_2      =	'([^'\\\n\r]|{ECHAR}|{UCHAR})*'{LANGTAG}
LANG_STRING_LITERAL_LONG1	 =	'''(('|'')?([^'\\]|{ECHAR}|{UCHAR}))*'''{LANGTAG}
LANG_STRING_LITERAL_LONG2	 =	"""(("|"")?([^"\\]|{ECHAR}|{UCHAR}))*"""{LANGTAG}

BASE           = [Bb][Aa][Ss][Ee]
PREFIX         = [Pp][Rr][Ee][Ff][Ii][Xx]
IMPORT         = [Ii][Mm][Pp][Oo][Rr][Tt]
START          = [Ss][Tt][Aa][Rr][Tt]
EXTERNAL       = [Ee][Xx][Tt][Ee][Rr][Nn][Aa][Ll]
AND            = [Aa][Nn][Dd]
OR             = [Oo][Rr]
NOT            = [Nn][Oo][Tt]
NONLITERAL     = [Nn][Oo][Nn][Ll][Ii][Tt][Ee][Rr][Aa][Ll]
LITERAL        = [Ll][Ii][Tt][Ee][Rr][Aa][Ll]
IRI            = [Ii][Rr][Ii]
BNODE          = [Bb][Nn][Oo][Dd][Ee]
MINLENGTH      = [Mm][Ii][Nn][Ll][Ee][Nn][Gg][Tt][Hh]
MAXLENGTH      = [Mm][Aa][Xx][Ll][Ee][Nn][Gg][Tt][Hh]
LENGTH         = [Ll][Ee][Nn][Gg][Tt][Hh]
MININCLUSIVE   = [Mm][Ii][Nn][Ii][Nn][Cc][Ll][Uu][Ss][Ii][Vv][Ee]
MINEXCLUSIVE   = [Mm][Ii][Nn][Ee][Xx][Cc][Ll][Uu][Ss][Ii][Vv][Ee]
MAXINCLUSIVE   = [Mm][Aa][Xx][Ii][Nn][Cc][Ll][Uu][Ss][Ii][Vv][Ee]
MAXEXCLUSIVE   = [Mm][Aa][Xx][Ee][Xx][Cc][Ll][Uu][Ss][Ii][Vv][Ee]
TOTALDIGITS    = [Tt][Oo][Tt][Aa][Ll][Dd][Ii][Gg][Ii][Tt][Ss]
FRACTIONDIGITS = [Ff][Rr][Aa][Cc][Tt][Ii][Oo][Nn][Dd][Ii][Gg][Ii][Tt][Ss]
CLOSED         = [Cc][Ll][Oo][Ss][Ee][Dd]
EXTRA          = [En][Xx][Tt][Rr][Aa]


Rules.

{BASE}                      : {token, {'BASE', TokenLine}}.
{PREFIX}                    : {token, {'PREFIX', TokenLine}}.
{IMPORT}                    : {token, {'IMPORT', TokenLine}}.
{START}                     : {token, {'START', TokenLine}}.
{EXTERNAL}                  : {token, {'EXTERNAL', TokenLine}}.
{AND}                       : {token, {'AND', TokenLine}}.
{OR}                        : {token, {'OR', TokenLine}}.
{NOT}                       : {token, {'NOT', TokenLine}}.
{LITERAL}                   : {token, {'LITERAL', TokenLine}}.
{IRI}                       : {token, {'IRI', TokenLine}}.
{BNODE}                     : {token, {'BNODE', TokenLine}}.
{NONLITERAL}                : {token, {'NONLITERAL', TokenLine}}.
{LENGTH}										: {token, {'LENGTH', TokenLine}}.
{MINLENGTH}									: {token, {'MINLENGTH', TokenLine}}.
{MAXLENGTH}									: {token, {'MAXLENGTH', TokenLine}}.
{MININCLUSIVE}							: {token, {'MININCLUSIVE', TokenLine}}.
{MINEXCLUSIVE}							: {token, {'MINEXCLUSIVE', TokenLine}}.
{MAXINCLUSIVE}							: {token, {'MAXINCLUSIVE', TokenLine}}.
{MAXEXCLUSIVE}							: {token, {'MAXEXCLUSIVE', TokenLine}}.
{TOTALDIGITS}								: {token, {'TOTALDIGITS', TokenLine}}.
{FRACTIONDIGITS}						: {token, {'FRACTIONDIGITS', TokenLine}}.
{CLOSED}										: {token, {'CLOSED', TokenLine}}.
{EXTRA}	  									: {token, {'EXTRA', TokenLine}}.

{CODE}                      : {token, {code, TokenLine, code_str(TokenChars)}}.
{LANGTAG}                   : {token, {langtag, TokenLine, langtag_str(TokenChars)}}.
{IRIREF}                    : {token, {iriref,  TokenLine, quoted_content_str(TokenChars)}}.
{DOUBLE}                    : {token, {double, TokenLine, double(TokenChars)}}.
{DECIMAL}                   : {token, {decimal, TokenLine, decimal(TokenChars)}}.
{INTEGER}	                  : {token, {integer,  TokenLine, integer(TokenChars)}}.
{BOOLEAN}                   : {token, {boolean, TokenLine, boolean(TokenChars)}}.
{REPEAT_RANGE}							: {token, {repeat_range, TokenLine, repeat_range(TokenChars)}}.
{REGEXP}										: {token, {regexp, TokenLine, regexp_str(TokenChars)}}.
{REGEXP_FLAGS}		   				: {token, {regexp_flags, TokenLine, regexp_flags_str(TokenChars)}}.
{STRING_LITERAL_1}          : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_2}          : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG1}      : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG2}      : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_1}     : {token, {lang_string_literal_quote, TokenLine, lang_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_2}     : {token, {lang_string_literal_quote, TokenLine, lang_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_LONG1} : {token, {lang_string_literal_quote, TokenLine, lang_long_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_LONG2} : {token, {lang_string_literal_quote, TokenLine, lang_long_quoted_content_str(TokenChars)}}.
{BLANK_NODE_LABEL}          : {token, {blank_node_label, TokenLine, bnode_str(TokenChars)}}.
a                           : {token, {rdf_type, TokenLine}}.
{PNAME_NS}                  : {token, {prefix_ns, TokenLine, prefix_ns(TokenChars)}}.
{PNAME_LN}                  : {token, {prefix_ln, TokenLine, prefix_ln(TokenChars)}}.
{ATPNAME_NS}                : {token, {at_prefix_ns, TokenLine, at_prefix_ns(TokenChars)}}.
{ATPNAME_LN}                : {token, {at_prefix_ln, TokenLine, at_prefix_ln(TokenChars)}}.
; 	                        : {token, {';', TokenLine}}.
\.	                        : {token, {'.', TokenLine}}.
\[	                        : {token, {'[', TokenLine}}.
\]	                        : {token, {']', TokenLine}}.
\(	                        : {token, {'(', TokenLine}}.
\)	                        : {token, {')', TokenLine}}.
\{	                        : {token, {'{', TokenLine}}.
\}	                        : {token, {'}', TokenLine}}.
\^	                        : {token, {'^', TokenLine}}.
\^\^	                      : {token, {'^^', TokenLine}}.
\=	                        : {token, {'=', TokenLine}}.
\@	                        : {token, {'@', TokenLine}}.
\$	                        : {token, {'$', TokenLine}}.
\%	                        : {token, {'%', TokenLine}}.
\|	                        : {token, {'|', TokenLine}}.
\&	                        : {token, {'&', TokenLine}}.
\?	                        : {token, {'?', TokenLine}}.
\*	                        : {token, {'*', TokenLine}}.
\+	                        : {token, {'+', TokenLine}}.
\-	                        : {token, {'-', TokenLine}}.
\~	                        : {token, {'~', TokenLine}}.
\/\/	                      : {token, {'//', TokenLine}}.
{COMMENT}                   : skip_token.
{PASSED_TOKENS}             : skip_token.


Erlang code.

integer(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':integer(TokenChars).
decimal(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':decimal(TokenChars).
double(TokenChars)   -> 'Elixir.RDF.Serialization.ParseHelper':double(TokenChars).
boolean(TokenChars)  -> 'Elixir.RDF.Serialization.ParseHelper':boolean(TokenChars).
quoted_content_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':quoted_content_str(TokenChars).
long_quoted_content_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':long_quoted_content_str(TokenChars).
bnode_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':bnode_str(TokenChars).
langtag_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':langtag_str(TokenChars).
prefix_ns(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ns(TokenChars).
prefix_ln(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ln(TokenChars).
at_prefix_ns(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ns(string:slice(TokenChars,1)).
at_prefix_ln(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':prefix_ln(string:slice(TokenChars,1)).

lang_quoted_content_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':lang_quoted_content_str(TokenChars).
lang_long_quoted_content_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':lang_long_quoted_content_str(TokenChars).
code_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':code_str(TokenChars).
repeat_range(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':repeat_range(TokenChars).
regexp_str(TokenChars) -> 'Elixir.RDF.Serialization.ParseHelper':quoted_content_str(TokenChars).
regexp_flags_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':to_str(TokenChars).
