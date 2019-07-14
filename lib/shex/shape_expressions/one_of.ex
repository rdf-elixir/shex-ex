defmodule ShEx.OneOf do
  @moduledoc false

  defstruct [
    :id,          # tripleExprLabel?
    :expressions, # [tripleExpr{2,}]
    :min,         # INTEGER?
    :max,         # INTEGER?
    :sem_acts,    # [SemAct+]?
    :annotations  # [Annotation+]?
  ]

  import ShEx.TripleExpression.Shared

  def matches(one_of, triples, graph, schema, association, state) do
    with {matched, remainder, match_count, violations} <-
           find_matches(triples, one_of, graph, schema, association, state),
         :ok <-
           check_cardinality(match_count,
             ShEx.TripleExpression.min_cardinality(one_of), one_of, violations)
    do
      {:ok, matched, remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, one_of, graph, schema, association, state) do
    do_find_matches({:ok, [], triples, 0, []},
      one_of.expressions, ShEx.TripleExpression.max_cardinality(one_of),
      graph, schema, association, state)
  end

  defp do_find_matches({:ok, matched, remainder, max, violations}, _, max, _, _, _, _),
    do: {matched, remainder, max, violations}

  defp do_find_matches({:ok, matched, remainder, match_count, violations},
         expressions, max, graph, schema, association, state) do
    expressions
    |> Enum.reduce_while({matched, remainder, match_count, violations}, fn
        expression, {matched, remainder, match_count, violations} ->
          ShEx.TripleExpression.matches(
            expression, remainder, graph, schema, association, state)
          |> case do
               {:ok, new_matched, new_remainder} ->
                 {:halt, {:ok, new_matched, new_remainder, match_count + 1, violations}}

               {:error, violation} ->
                 {:cont, {matched, remainder, match_count, violations ++ List.wrap(violation)}}
             end
        end)
    |> do_find_matches(expressions, max, graph, schema, association, state)
  end

  defp do_find_matches(acc, _, _, _, _, _, _), do: acc


  defimpl ShEx.TripleExpression do
    def matches(one_of, triples, graph, schema, association, state) do
      ShEx.OneOf.matches(one_of, triples, graph, schema, association, state)
    end

    def min_cardinality(one_of), do: ShEx.TripleExpression.Shared.min_cardinality(one_of)
    def max_cardinality(one_of), do: ShEx.TripleExpression.Shared.max_cardinality(one_of)

    def predicates(one_of, state),
      do: ShEx.TripleExpression.Shared.predicates_of_group(one_of, state)

    def triple_constraints(one_of, state),
      do: ShEx.TripleExpression.Shared.triple_constraints_of_group(one_of, state)

    def required_arcs(one_of, state),
      do: ShEx.TripleExpression.Shared.required_arcs_of_group(one_of, state)
  end

  defimpl ShEx.Operator do
    def triple_expression_label_and_operands(one_of),
      do: {one_of.id, one_of.expressions}
  end
end
