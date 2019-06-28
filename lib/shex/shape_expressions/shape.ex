defmodule ShEx.Shape do
  defstruct [
    :id,          # shapeExprLabel?
    :expression,  # tripleExpr?
    :closed,      # BOOL?
    :extra,       # [IRI]?
    :sem_acts,    # [SemAct]?
    :annotations  # [Annotation+]?
  ]

  import ShEx.GraphUtils


  def satisfies(shape, graph, schema, association, shape_map, ref_stack) do
    node = association.node
    arcs_out = arcs_out(graph, node)
    arcs_in = arcs_in(graph, node)

    with {:ok, _matched, {_, outs}} <-
            matches(shape.expression, {arcs_in, arcs_out}, graph, schema, association, shape_map, ref_stack),

         {matchables, unmatchables} <-
           matchables(shape.expression, outs),

         :ok <-
           check_unmatched(shape.expression, matchables, graph, schema, association, shape_map, ref_stack),

         :ok <-
           check_extra(List.wrap(shape.extra), matchables, shape.expression),

         :ok <-
           check_closed(shape.closed, unmatchables, shape)
    do
      ShEx.ShapeMap.Association.conform(association)
    else
      {:error, violation} ->
        ShEx.ShapeMap.Association.violation(association, violation)
    end
  end

  defp matches(nil, triples, _, _, _, _, _) do
    {:ok, [], triples}
  end

  defp matches(triple_constraint, triples, graph, schema, association, shape_map, ref_stack) do
    ShEx.TripleExpression.matches(
        triple_constraint, triples, graph, schema, association, shape_map, ref_stack)
  end

  # Let `matchables` be the triples in `outs` whose predicate appears in a `TripleConstraint` in `expression`. If `expression` is absent, `matchables = Ø` (the empty set).
  # Let `unmatchables` be the triples in `outs` which are not in `matchables`.
  defp matchables(nil, outs), do: {[], outs}
  defp matchables(triple_constraint, outs) do
    predicates = ShEx.TripleExpression.predicates(triple_constraint)
    Enum.split_with(outs, fn {_, predicate, _} -> predicate in predicates end)
  end

  # No matchable can be matched by any TripleConstraint in expression
  defp check_unmatched(nil, _, _, _, _, _, _), do: :ok
  defp check_unmatched(triple_constraint, matchables, graph, schema, association, shape_map, ref_stack) do
    if triple_constraint
       |> matching_unmatched(matchables, graph, schema, association, shape_map, ref_stack)
       |> Enum.empty?()
    do
      :ok
    else
      {:error, %ShEx.Violation.MaxCardinality{triple_expression: triple_constraint}}
    end
  end

  defp matching_unmatched(triple_constraint, matchables, graph, schema, association, shape_map, ref_stack) do
    triple_constraints =
      triple_constraint
      |> ShEx.TripleExpression.triple_constraints()
        # We'll reset the cardinality here, because one match is sufficient ...
      |> Enum.map(fn expression -> expression |> Map.put(:min, nil) |> Map.put(:max, nil) end)
    Enum.filter(matchables, fn {_, predicate, _} = statement ->
      Enum.any?(triple_constraints, fn triple_constraint ->
        triple_constraint.predicate == predicate and
          match?({:ok, _, _},
            matches(triple_constraint, {[], [statement]}, graph, schema, association, shape_map, ref_stack))
      end)
    end)
  end

  # There is no triple in matchables whose predicate does not appear in extra.
  defp check_extra(extra, matchables, triple_expressions) do
    if Enum.all?(matchables, fn {_, predicate, _} -> predicate in extra end) do
      :ok
    else
      {:error, %ShEx.Violation.MaxCardinality{triple_expression: triple_expressions}}
    end
  end

  # closed is false or unmatchables is empty.
  defp check_closed(closed, unmatchables, shape) do
    if !closed || Enum.empty?(unmatchables) do
      :ok
    else
      {:error, %ShEx.Violation.ClosedShape{shape: shape, unmatchables: unmatchables}}
    end
  end


  defimpl ShEx.ShapeExpression do
    def satisfies(shape, graph, schema, association, shape_map, ref_stack) do
      ShEx.Shape.satisfies(shape, graph, schema, association, shape_map, ref_stack)
    end
  end
end
