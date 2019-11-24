defmodule ShEx.ShapeMap.Decoder do
  @moduledoc !"""
             Decoder for standard representation format for ShapeMaps specified in <https://shexspec.github.io/shape-map/>.
             """

  import ShEx.Utils

  alias RDF.{IRI, BlankNode, Literal}

  def decode(content, opts \\ []) do
    with {:ok, tokens, _} <- tokenize(content),
         {:ok, ast} <- parse(tokens) do
      build_shape_map(ast, opts)
    else
      {:error, {error_line, :shape_map_lexer, error_descriptor}, _error_line_again} ->
        {:error,
         "ShapeMap scanner error on line #{error_line}: #{error_description(error_descriptor)}"}

      {:error, {error_line, :shape_map_parser, error_descriptor}} ->
        {:error,
         "ShapeMap parser error on line #{error_line}: #{error_description(error_descriptor)}"}
    end
  end

  defp error_description(error_descriptor) when is_list(error_descriptor) do
    error_descriptor
    |> Stream.map(&to_string/1)
    |> Enum.join("")
  end

  defp error_description(error_descriptor), do: inspect(error_descriptor)

  defp tokenize(content), do: content |> to_charlist |> :shape_map_lexer.string()

  defp parse([]), do: {:ok, []}
  defp parse(tokens), do: tokens |> :shape_map_parser.parse()

  defp build_shape_map(shape_associations_ast, opts) do
    with {:ok, associations} <-
           map(shape_associations_ast, &build_association/2, opts) do
      {:ok, ShEx.ShapeMap.new(associations)}
    end
  end

  defp build_association({{:node, node_ast}, shape_ast}, opts) do
    with {:ok, node} <- build_node(node_ast, opts),
         {:ok, shape} <- build_shape(shape_ast, opts) do
      {:ok, ShEx.ShapeMap.Association.new(node, shape)}
    end
  end

  defp build_association({{:triple_pattern, triple_pattern_ast}, shape_ast}, opts) do
    with {:ok, triple_pattern} <- build_triple_pattern(triple_pattern_ast, opts),
         {:ok, shape} <- build_shape(shape_ast, opts) do
      {:ok, ShEx.ShapeMap.Association.new(triple_pattern, shape)}
    end
  end

  defp build_shape(:start, _opts), do: {:ok, :start}
  defp build_shape(node, opts), do: build_node(node, opts)

  defp build_node(%IRI{} = iri, _opts), do: {:ok, iri}
  defp build_node(%BlankNode{} = bnode, _opts), do: {:ok, bnode}
  defp build_node(%Literal{} = literal, _opts), do: {:ok, literal}

  defp build_node({{:string_literal_quote, _line, value}, {:datatype, datatype}}, opts) do
    with {:ok, datatype} <- build_node(datatype, opts) do
      {:ok, RDF.literal(value, datatype: datatype)}
    end
  end

  defp build_triple_pattern({subject_ast, predicate_ast, object_ast}, opts) do
    with {:ok, subject_node_pattern} <- build_node_pattern(subject_ast, opts),
         {:ok, predicate_node_pattern} <- build_predicate_pattern(predicate_ast, opts),
         {:ok, object_node_pattern} <- build_node_pattern(object_ast, opts) do
      {:ok, {subject_node_pattern, predicate_node_pattern, object_node_pattern}}
    end
  end

  defp build_node_pattern(keyword, _opts) when is_atom(keyword), do: {:ok, keyword}
  defp build_node_pattern(node_pattern_ast, opts), do: build_node(node_pattern_ast, opts)

  defp build_predicate_pattern(:rdf_type, _opts), do: {:ok, RDF.type()}
  defp build_predicate_pattern(iri, _opts), do: {:ok, iri}
end
