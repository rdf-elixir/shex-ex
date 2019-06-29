defmodule ShEx.TripleExpressionReference do
  def matches(triple_expression_ref, triples, graph, schema, association, state) do
    triple_expression_ref
    |> triple_expression_with_id(state)
    |> ShEx.TripleExpression.matches(triples, graph, schema, association, state)
  end

  def predicates(triple_expression_ref, state) do
    triple_expression_ref
    |> triple_expression_with_id(state)
    |> ShEx.TripleExpression.predicates(state)
  end

  def triple_constraints(triple_expression_ref, state) do
    triple_expression_ref
    |> triple_expression_with_id(state)
    |> ShEx.TripleExpression.triple_constraints(state)
  end

  def required_arcs(triple_expression_ref, state) do
    triple_expression_ref
    |> triple_expression_with_id(state)
    |> ShEx.TripleExpression.required_arcs(state)
  end

  def triple_expression_with_id(triple_expression_ref, state) do
    get_in(state, [:labeled_triple_expressions, triple_expression_ref]) ||
      raise "unknown TripleExprLabel: #{inspect triple_expression_ref}"
  end
end

defimpl ShEx.TripleExpression, for: RDF.IRI do
  def matches(triple_expression_ref, triples, graph, schema, association, state),
    do: ShEx.TripleExpressionReference.matches(
          triple_expression_ref, triples, graph, schema, association, state)

  def predicates(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.predicates(triple_expression_ref, state)

  def triple_constraints(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.triple_constraints(triple_expression_ref, state)

  def required_arcs(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.required_arcs(triple_expression_ref, state)
end

defimpl ShEx.TripleExpression, for: RDF.BlankNode do
  def matches(triple_expression_ref, triples, graph, schema, association, state),
    do: ShEx.TripleExpressionReference.matches(
          triple_expression_ref, triples, graph, schema, association, state)

  def predicates(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.predicates(triple_expression_ref, state)

  def triple_constraints(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.triple_constraints(triple_expression_ref, state)

  def required_arcs(triple_expression_ref, state),
    do: ShEx.TripleExpressionReference.required_arcs(triple_expression_ref, state)
end
