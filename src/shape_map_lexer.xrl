%% \00=NULL
%% \01-\x1F=control codes
%% \x20=space

Definitions.

COMMENT = #[^\n\r]*
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


EXPONENT	=	([eE][+-]?[0-9]+)
INTEGER	  =	[+-]?[0-9]+
DECIMAL	  =	[+-]?[0-9]*\.[0-9]+
DOUBLE	  =	[+-]?([0-9]+\.[0-9]*{EXPONENT}|\.[0-9]+{EXPONENT}|[0-9]+{EXPONENT})
BOOLEAN   = true|false

AT_START = @START
%% The AT_START terminal has precendence over LANGTAG

LANGTAG	=	@[a-zA-Z]+(-[a-zA-Z0-9]+)*

STRING_LITERAL_1           = "([^"\\\n\r]|{ECHAR}|{UCHAR})*"
STRING_LITERAL_2           =	'([^'\\\n\r]|{ECHAR}|{UCHAR})*'
STRING_LITERAL_LONG1	     =	'''(('|'')?([^'\\]|{ECHAR}|{UCHAR}))*'''
STRING_LITERAL_LONG2	     =	"""(("|"")?([^"\\]|{ECHAR}|{UCHAR}))*"""
LANG_STRING_LITERAL_1      = "([^"\\\n\r]|{ECHAR}|{UCHAR})*"{LANGTAG}
LANG_STRING_LITERAL_2      =	'([^'\\\n\r]|{ECHAR}|{UCHAR})*'{LANGTAG}
LANG_STRING_LITERAL_LONG1	 =	'''(('|'')?([^'\\]|{ECHAR}|{UCHAR}))*'''{LANGTAG}
LANG_STRING_LITERAL_LONG2	 =	"""(("|"")?([^"\\]|{ECHAR}|{UCHAR}))*"""{LANGTAG}

IRIREF = <([^\x00-\x20<>"{}|^`\\]|{UCHAR})*>
BLANK_NODE_LABEL = _:({PN_CHARS_U}|[0-9])(({PN_CHARS}|\.)*({PN_CHARS}))?


Rules.

{AT_START}                  : {token, {at_start, TokenLine}}.
START                       : {token, {'START', TokenLine}}.
FOCUS                       : {token, {'FOCUS', TokenLine}}.
{LANGTAG}                   : {token, {langtag, TokenLine, langtag_str(TokenChars)}}.
{IRIREF}                    : {token, {iriref,  TokenLine, quoted_content_str(TokenChars)}}.
{BLANK_NODE_LABEL}          : {token, {blank_node_label, TokenLine, bnode_str(TokenChars)}}.
{DOUBLE}                    : {token, {double, TokenLine, double(TokenChars)}}.
{DECIMAL}                   : {token, {decimal, TokenLine, decimal(TokenChars)}}.
{INTEGER}	                  : {token, {integer,  TokenLine, integer(TokenChars)}}.
{BOOLEAN}                   : {token, {boolean, TokenLine, boolean(TokenChars)}}.
{STRING_LITERAL_1}          : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_2}          : {token, {string_literal_quote, TokenLine, quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG1}      : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{STRING_LITERAL_LONG2}      : {token, {string_literal_quote, TokenLine, long_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_1}     : {token, {lang_string_literal_quote, TokenLine, lang_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_2}     : {token, {lang_string_literal_quote, TokenLine, lang_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_LONG1} : {token, {lang_string_literal_quote, TokenLine, lang_long_quoted_content_str(TokenChars)}}.
{LANG_STRING_LITERAL_LONG2} : {token, {lang_string_literal_quote, TokenLine, lang_long_quoted_content_str(TokenChars)}}.
a                           : {token, {rdf_type, TokenLine}}.
_	                          : {token, {'_', TokenLine}}.
\,	                        : {token, {',', TokenLine}}.
\{	                        : {token, {'{', TokenLine}}.
\}	                        : {token, {'}', TokenLine}}.
\^\^	                      : {token, {'^^', TokenLine}}.
\@	                        : {token, {'@', TokenLine}}.

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

lang_quoted_content_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':lang_quoted_content_str(TokenChars).
lang_long_quoted_content_str(TokenChars) -> 'Elixir.ShEx.ShExC.ParseHelper':lang_long_quoted_content_str(TokenChars).
