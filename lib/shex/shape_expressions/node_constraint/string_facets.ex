defmodule ShEx.NodeConstraint.StringFacets do
  defstruct ~w[length minlength maxlength pattern flags]a

  alias RDF.{IRI, BlankNode, Literal}

  def new(xs_facets) do
    string_facets = struct(__MODULE__, xs_facets)
    if %__MODULE__{} != string_facets do
      string_facets
    end
  end

  # TODO: instead of checking on every application to a node which constraints are there and must be applied, this could be compiled into minimal constraint checker
  def satisfies?(nil, _), do: true

  def satisfies?(string_facets, node) do
    if lex = lexical_form(node) do
      len = String.length(lex)

      satisfies_string_length?(string_facets.length, len) &&
        satisfies_string_minlength?(string_facets.minlength, len) &&
        satisfies_string_maxlength?(string_facets.maxlength, len) &&
        satisfies_string_pattern?(string_facets, lex)
    end
  end

  defp satisfies_string_length?(nil, _), do: true
  defp satisfies_string_length?(length, len), do: length == len

  defp satisfies_string_minlength?(nil, _), do: true
  defp satisfies_string_minlength?(minlength, len), do: minlength <= len

  defp satisfies_string_maxlength?(nil, _), do: true
  defp satisfies_string_maxlength?(maxlength, len), do: maxlength >= len

  defp satisfies_string_pattern?(%{pattern: nil}, _), do: true
  defp satisfies_string_pattern?(%{pattern: pattern, flags: flags}, lex) do
    RDF.Literal.matches?(lex, pattern, flags || "")
  end

  defp lexical_form(%IRI{value: value}), do: value
  defp lexical_form(%BlankNode{id: id}), do: id
  defp lexical_form(%Literal{} = literal), do: Literal.lexical(literal)
  defp lexical_form(_), do: nil
end
