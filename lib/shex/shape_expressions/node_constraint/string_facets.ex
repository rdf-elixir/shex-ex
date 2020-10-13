defmodule ShEx.NodeConstraint.StringFacets do
  @moduledoc false

  defstruct ~w[length minlength maxlength pattern flags]a

  alias RDF.{IRI, BlankNode, Literal}

  def new(xs_facets) do
    string_facets = struct(__MODULE__, xs_facets)

    if %__MODULE__{} != string_facets do
      string_facets
    end
  end

  # TODO: instead of checking on every application to a node which constraints are there and must be applied, this could be compiled into minimal constraint checker
  def satisfies(string_facets, node)

  def satisfies(nil, _), do: :ok

  def satisfies(string_facets, node) do
    lex = lexical_form(node)
    len = String.length(lex)

    with true <- satisfies_string_length(string_facets.length, len),
         true <- satisfies_string_minlength(string_facets.minlength, len),
         true <- satisfies_string_maxlength(string_facets.maxlength, len),
         true <- satisfies_string_pattern(string_facets, lex) do
      :ok
    else
      {:violates, type, value} ->
        %ShEx.Violation.StringFacetConstraint{
          facet_type: type,
          facet_value: value,
          node: node
        }
    end
  end

  defp satisfies_string_length(nil, _), do: true

  defp satisfies_string_length(length, len) do
    length == len || {:violates, :length, length}
  end

  defp satisfies_string_minlength(nil, _), do: true

  defp satisfies_string_minlength(minlength, len) do
    minlength <= len || {:violates, :minlength, minlength}
  end

  defp satisfies_string_maxlength(nil, _), do: true

  defp satisfies_string_maxlength(maxlength, len) do
    maxlength >= len || {:violates, :maxlength, maxlength}
  end

  defp satisfies_string_pattern(%{pattern: nil}, _), do: true

  defp satisfies_string_pattern(%{pattern: pattern, flags: flags} = pattern_facet, lex) do
    RDF.Literal.matches?(lex, pattern, flags || "") ||
      {:violates, :pattern, pattern_facet}
  end

  defp lexical_form(%IRI{value: value}), do: value
  defp lexical_form(%BlankNode{value: value}), do: value
  defp lexical_form(%Literal{} = literal), do: Literal.lexical(literal)
  defp lexical_form(value), do: raise("Invalid node value: #{inspect(value)}}")
end
