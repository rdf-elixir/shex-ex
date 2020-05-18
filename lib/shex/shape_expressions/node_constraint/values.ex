defmodule ShEx.NodeConstraint.Values do
  @moduledoc false

  alias RDF.{IRI, Literal}

  @wildcard %{type: "Wildcard"}
  def wildcard(), do: @wildcard

  def new(values_constraints) when is_list(values_constraints) do
    Enum.map(values_constraints, &normalize_value_constraint/1)
  end

  def new(nil), do: nil

  defp normalize_value_constraint(
         %{type: "LiteralStemRange", exclusions: exclusions} = stem_range
       ) do
    # TODO: instead of checking for the presence of exclusions, we maybe want to normalize StemRange to a Stem?
    %{
      stem_range
      | exclusions:
          exclusions &&
            Enum.map(exclusions, fn
              string when is_binary(string) -> Literal.new(string)
              exclusion -> exclusion
            end)
    }
  end

  defp normalize_value_constraint(value_constraint), do: value_constraint

  def satisfies(nil, _), do: :ok
  def satisfies([], _), do: :ok

  def satisfies(values, node) do
    Enum.reduce_while(values, [], fn value, violations ->
      case satisfies_value(value, node) do
        :ok -> {:halt, :ok}
        violation -> {:cont, [violation | violations]}
      end
    end)
  end

  def satisfies_value(%IRI{} = node, node), do: :ok

  def satisfies_value(%IRI{} = iri, node) do
    %ShEx.Violation.ValuesConstraint{
      constraint_type: :object_value,
      constraint_value: iri,
      node: node
    }
  end

  def satisfies_value(%Literal{} = node, node), do: :ok

  def satisfies_value(%Literal{} = literal, node) do
    %ShEx.Violation.ValuesConstraint{
      constraint_type: :object_value,
      constraint_value: literal,
      node: node
    }
  end

  def satisfies_value(%{type: "Language", languageTag: language_tag}, node) do
    if match_language?(node, language_tag) do
      :ok
    else
      %ShEx.Violation.ValuesConstraint{
        constraint_type: :language,
        constraint_value: language_tag,
        node: node
      }
    end
  end

  def satisfies_value(%{type: type} = stem, node)
      when type in ~w[IriStem LiteralStem LanguageStem] do
    if node_in?(stem, node) do
      :ok
    else
      %ShEx.Violation.ValuesConstraint{
        constraint_type: type,
        constraint_value: stem.stem,
        node: node
      }
    end
  end

  def satisfies_value(%{type: type} = stem_range, node)
      when type in ~w[IriStemRange LiteralStemRange LanguageStemRange] do
    cond do
      stem_range.stem != @wildcard and not node_in?(stem_range, node) ->
        %ShEx.Violation.ValuesConstraint{
          constraint_type: type,
          constraint_value: stem_range.stem,
          node: node
        }

      type != "LanguageStemRange" and
          Enum.any?(stem_range.exclusions, fn exclusion -> node_in?(exclusion, node) end) ->
        %ShEx.Violation.ValuesConstraint{
          constraint_type: :exclusion,
          constraint_value: stem_range.exclusions,
          node: node
        }

      type == "LanguageStemRange" and
          Enum.any?(stem_range.exclusions, fn
            excluded_lang_tag when is_binary(excluded_lang_tag) ->
              # objectValues should be treated as language tags
              match_language?(node, excluded_lang_tag)

            exclusion ->
              node_in?(exclusion, node)
          end) ->
        %ShEx.Violation.ValuesConstraint{
          constraint_type: :exclusion,
          constraint_value: stem_range.exclusions,
          node: node
        }

      true ->
        :ok
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
    language = if language_stem == "", do: "*", else: language_stem
    RDF.LangString.match_language?(node, language)
  end

  defp node_in?(node, node), do: true
  defp node_in?(_, _), do: false

  defp match_language?(%Literal{literal: %RDF.LangString{language: language}}, ""),
    do: not is_nil(language)

  defp match_language?(%Literal{literal: %RDF.LangString{language: language}}, expected_language),
    do: language == String.downcase(expected_language)

  defp match_language?(_, _), do: false
end
