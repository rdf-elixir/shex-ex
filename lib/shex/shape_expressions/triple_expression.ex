defprotocol ShEx.TripleExpression do
  @moduledoc !"""
  Triple expressions are used for defining patterns composed of triple constraints.
  """

  @doc """
  Asserts that a triple expression is matched by a set of triples that come from the neighbourhood of a node in an RDF graph.
  """
  def matches(triple_expression, triples, graph, schema, association, state)

  def min_cardinality(triple_expression)

  def max_cardinality(triple_expression)

  def predicates(triple_expression, state)

  def triple_constraints(triple_expression, state)

  def required_arcs(triple_expression, state)
end

defmodule ShEx.TripleExpression.Shared do
  @moduledoc false

  def min_cardinality(triple_expression), do: triple_expression.min || 1
  def max_cardinality(triple_expression), do: triple_expression.max || 1

  def check_cardinality(count, min, triple_expression, violations) when count < min do
    %ShEx.Violation.MinCardinality{
      triple_expression: triple_expression,
      triple_expression_violations: violations,
      cardinality: count
    }
  end

  def check_cardinality(_, _, _, _), do: :ok

  def triple_constraints_of_group(group, state) do
    group.expressions
    |> Enum.flat_map(&(ShEx.TripleExpression.triple_constraints(&1, state)))
    |> MapSet.new()
    |> MapSet.to_list()
  end

  def predicates_of_group(group, state) do
    group.expressions
    |> Enum.flat_map(&(ShEx.TripleExpression.predicates(&1, state)))
    |> MapSet.new()
  end

  def required_arcs_of_group(group, state) do
    Enum.reduce_while(group.expressions, nil, fn expression, arcs_type ->
      expression
      |> ShEx.TripleExpression.required_arcs(state)
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
end
