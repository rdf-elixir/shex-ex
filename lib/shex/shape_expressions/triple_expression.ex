defprotocol ShEx.TripleExpression do
  @moduledoc """
  Triple expressions are used for defining patterns composed of triple constraints.
  """

  @doc """
  Asserts that a triple expression is matched by a set of triples that come from the neighbourhood of a node in an RDF graph.
  """
  def matches(triple_expression, triples, graph, schema, association, shape_map, ref_stack)

  def predicates(triple_expression)

  def triple_constraints(triple_expression)

  def required_arcs(triple_expression)
end

defmodule ShEx.TripleExpression.Shared do
  def triple_expression(%RDF.IRI{} = triple_expression_ref),
    do: triple_expression_with_id(%RDF.IRI{} = triple_expression_ref)

  def triple_expression(triple_expression),
    do: triple_expression

  def triple_expression_with_id(%RDF.IRI{} = triple_expression_ref) do
    raise "NotImplemented: resolve IRIref"
  end

  def triple_constraints_of_group(group) do
    group.expressions
    |> Enum.flat_map(&ShEx.TripleExpression.triple_constraints/1)
    |> MapSet.new()
    |> MapSet.to_list()
  end

  def predicates_of_group(group) do
    group.expressions
    |> Enum.flat_map(&ShEx.TripleExpression.predicates/1)
    |> MapSet.new()
  end

  def required_arcs_of_group(group) do
    Enum.reduce_while(group.expressions, nil, fn expression, arcs_type ->
      expression
      |> ShEx.TripleExpression.required_arcs()
      |> triple_expression()
      |> case do
          {:ok, first_arcs_type} when is_nil(first_arcs_type) ->
            {:cont, {:ok, {arcs_type}}}

          {:ok, ^arcs_type} ->
            {:cont, {:ok, {arcs_type}}}

          {:ok, _} ->
            {:halt, {:ok, {:arcs_in, :arcs_out}}}

          {:error, _} = error ->
            {:halt, error}
        end
    end)
  end


  def check_cardinality(count, min, triple_expression) when count < min do
    %ShEx.Violation.MinCardinality{
      triple_expression: triple_expression,
      cardinality: count
    }
  end

  def check_cardinality(_, _, _), do: :ok
end
