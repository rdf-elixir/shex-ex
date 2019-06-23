defmodule ShEx.OneOf do
  defstruct [
    :id,          # tripleExprLabel?
    :expressions, # [tripleExpr{2,}]
    :min,         # INTEGER?
    :max,         # INTEGER?
    :sem_acts,    # [SemAct+]?
    :annotations  # [Annotation+]?
  ]

  import ShEx.TripleExpression.Shared

  def matches(one_of, triples, graph, schema, association, shape_map) do
    with {matched, remainder, match_count} <-
           find_matches(triples, one_of, graph, schema, association, shape_map),
         :ok <-
           check_cardinality(match_count, one_of.min || 1, one_of)
    do
      {:ok, matched, remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, one_of, graph, schema, association, shape_map) do
    do_find_matches({:ok, [], triples, 0},
      one_of.expressions, one_of.max || 1, graph, schema, association, shape_map)
  end

  defp do_find_matches({:ok, matched, remainder, max}, _, max, _, _, _, _),
    do: {matched, remainder, max}

  defp do_find_matches({:ok, matched, remainder, match_count},
         expressions, max, graph, schema, association, shape_map) do
    expressions
    |> Enum.reduce_while({matched, remainder, match_count}, fn
        expression, {matched, remainder, match_count} ->
          with {:ok, new_matched, new_remainder} <-
                 expression
                 |> triple_expression()
                 |> ShEx.TripleExpression.matches(remainder, graph, schema, association, shape_map)
          do
            {:halt, {:ok, new_matched, new_remainder, match_count + 1}}
          else
            {:error, error} ->
              # TODO: Maybe we want to pass the error instead of just providing a min cardinality violation as reason? see the same for EachOf
              {:cont, {matched, remainder, match_count}}
          end
    end)
    |> do_find_matches(expressions, max, graph, schema, association, shape_map)
  end

  defp do_find_matches(acc, _, _, _, _, _, _), do: acc


  defimpl ShEx.TripleExpression do
    def matches(one_of, triples, graph, schema, association, shape_map) do
      ShEx.OneOf.matches(one_of, triples, graph, schema, association, shape_map)
    end

    def predicates(one_of),
      do: ShEx.TripleExpression.Shared.predicates_of_group(one_of)

    def triple_constraints(one_of),
      do: ShEx.TripleExpression.Shared.triple_constraints_of_group(one_of)

    def required_arcs(one_of),
      do: ShEx.TripleExpression.Shared.required_arcs_of_group(one_of)
  end
end
