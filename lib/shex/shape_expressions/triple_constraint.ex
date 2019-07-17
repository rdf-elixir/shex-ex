defmodule ShEx.TripleConstraint do
  @moduledoc false

  defstruct [
    :id,          #	tripleExprLabel?
    :value_expr,  # shapeExpr?
    :predicate,   #	IRIREF
    :inverse,     #	BOOL?
    :min,         # INTEGER?
    :max,         # INTEGER?
    :sem_acts,    # [SemAct+]?
    :annotations  # [Annotation+]?
  ]

  import ShEx.TripleExpression.Shared


  def matches(%__MODULE__{inverse: true} = triple_constraint, {arcs_in, arcs_out},
        graph, schema, association, state) do
    with {:ok, matched, remainder} <-
           matches(triple_constraint, arcs_in, graph, schema, association, state) do
      {:ok, matched, {remainder, arcs_out}}
    end
  end

  def matches(triple_constraint, {arcs_in, arcs_out}, graph, schema, association, state) do
    with {:ok, matched, remainder} <-
           matches(triple_constraint, arcs_out, graph, schema, association, state) do
      {:ok, matched, {arcs_in, remainder}}
    end
  end

  def matches(triple_constraint, triples, graph, schema, association, state) do
    with {matched, mismatched, remainder, violations} <-
           find_matches(triples, triple_constraint, graph, schema, association, state),
         :ok <-
           check_cardinality(length(matched),
             ShEx.TripleExpression.min_cardinality(triple_constraint), triple_constraint, violations)
    do
      {:ok, matched, mismatched ++ remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, triple_constraint, graph, schema, association, state) do
    do_find_matches(
      {[], [], triples, []},
      triple_constraint.value_expr,
      triple_constraint.predicate,
      triple_constraint.inverse,
      ShEx.TripleExpression.max_cardinality(triple_constraint),
      {graph, schema, association, state}
    )
  end

  defp do_find_matches(acc, value_expr, predicate, inverse, max, match_context)

  defp do_find_matches({_, _, [], _} = acc, _, _, _, _, _), do: acc

  defp do_find_matches({matched, _, _, _} = acc, _, _, _, max, _)
    when length(matched) == max, do: acc

  defp do_find_matches(
         {matched, mismatched, [{_, predicate, _} = statement | remainder], violations},
         nil, predicate, inverse, max, match_context) do
    {[statement | matched], mismatched, remainder, violations}
    |> do_find_matches(nil, predicate, inverse, max, match_context)
  end

  defp do_find_matches(
         {matched, mismatched, [{subject, predicate, object} = statement | remainder], violations},
         value_expr, predicate, inverse, max,
         {graph, schema, _association, state} = match_context) do
      value = if inverse, do: subject, else: object

      ShEx.ShapeExpression.satisfies(
               value_expr,
               graph,
               schema,
               ShEx.ShapeMap.Association.new(value, value_expr),
               state)
      |> case do
           %{status: :conformant} ->
             {[statement | matched], mismatched, remainder, violations}

           %{status: :nonconformant} = nonconformant ->
             {matched, [statement | mismatched], remainder, violations ++
               List.wrap(nonconformant.reason)}
         end
      |> do_find_matches(value_expr, predicate, inverse, max, match_context)
  end

  defp do_find_matches({matched, mismatched, [statement | remainder], violations},
         value_expr, predicate, inverse, max, match_context) do
    {matched, [statement | mismatched], remainder, violations}
    |> do_find_matches(value_expr, predicate, inverse, max, match_context)
  end


  defimpl ShEx.TripleExpression do
    def matches(triple_constraint, triples, graph, schema, association, state) do
      ShEx.TripleConstraint.matches(triple_constraint, triples, graph, schema, association, state)
    end

    def min_cardinality(triple_constraint), do: ShEx.TripleExpression.Shared.min_cardinality(triple_constraint)
    def max_cardinality(triple_constraint), do: ShEx.TripleExpression.Shared.max_cardinality(triple_constraint)

    def predicates(%ShEx.TripleConstraint{predicate: predicate}, _), do: [predicate]

    def triple_constraints(triple_constraint, _), do: [triple_constraint]

    def required_arcs(%ShEx.TripleConstraint{inverse: true}, _), do: {:ok, :arcs_in}
    def required_arcs(_, _), do: {:ok, :arcs_out}
  end

  defimpl ShEx.Operator do
    def children(triple_constraint) do
      cond do
        is_nil(triple_constraint.value_expr) ->
          []

        RDF.term?(triple_constraint.value_expr) ->
          [{:shape_expression_label, triple_constraint.value_expr}]

        true ->
          [triple_constraint.value_expr]
      end
    end

    def triple_expression_label_and_operands(triple_constraint),
      do: {triple_constraint.id, List.wrap(triple_constraint.value_expr)}
  end
end
