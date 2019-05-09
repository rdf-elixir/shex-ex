defmodule ShEx.NodeConstraint.Values do
  defstruct [:values]

  alias RDF.{IRI, Literal}

  @wildcard %{type: "Wildcard"}
  def wildcard(), do: @wildcard

  def satisfies?(nil, _), do: true

  def satisfies?(values, node) do
    Enum.any? values, fn
      %IRI{} = iri ->
        node == iri

      %Literal{} = literal ->
        node == literal

      %{type: "Language", languageTag: ""} ->
        not is_nil(node.language)

      %{type: "Language", languageTag: language_tag} ->
        match? %Literal{language: ^language_tag}, node

      %{type: type} = stem when type in ~w[IriStem LiteralStem LanguageStem] ->
        node_in?(stem, node)

      %{type: type} = stem_range when type in ~w[IriStemRange LiteralStemRange LanguageStemRange] ->
        (stem_range.stem == @wildcard or node_in?(stem_range, node)) and
          not Enum.any?(stem_range.exclusions, fn exclusion -> node_in?(exclusion, node) end)

      _ ->
        true
    end
  end

  defp node_in?(%{type: type, stem: %IRI{value: iri_stem}}, %IRI{} = node)
       when type in ["IriStem", "IriStemRange"] do
    String.starts_with?(node.value, iri_stem)
  end

  defp node_in?(%{type: type, stem: literal_stem}, %Literal{} = node)
       when type in ["LiteralStem", "LiteralStemRange"] do
    node
    |> Literal.lexical()
    |> String.starts_with?(literal_stem)
  end

  defp node_in?(%{type: type, stem: language_stem}, %Literal{} = node)
       when type in ["LanguageStem", "LanguageStemRange"] do
    RDF.LangString.match_language?(node, language_stem)
  end

  defp node_in?(node, node), do: true
  defp node_in?(_, _), do: false
end
