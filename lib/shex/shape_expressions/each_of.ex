defmodule ShEx.EachOf do
  defstruct [
    :id,          # tripleExprLabel?
    :expressions, # [tripleExpr{2,}]
    :min,         # INTEGER?
    :max,         # INTEGER?
    :sem_acts,    # [SemAct+]?
    :annotations  # [Annotation+]?
  ]

  import ShEx.TripleExpression.Shared

  def matches(each_of, triples, graph, schema, association, shape_map) do
    with {matched, remainder, match_count} <-
           find_matches(triples, each_of, graph, schema, association, shape_map),
         :ok <-
           check_cardinality(match_count, each_of.min || 1, each_of)
    do
      {:ok, matched, remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, each_of, graph, schema, association, shape_map) do
    do_find_matches({:ok, [], triples, 0},
      each_of.expressions, each_of.max || 1, graph, schema, association, shape_map)
  end

  defp do_find_matches({:ok, matched, remainder, max}, _, max, _, _, _, _),
     do: {matched, remainder, max}

  defp do_find_matches({:ok, matched, remainder, match_count},
         expressions, max, graph, schema, association, shape_map) do
    expressions
    |> Enum.reduce_while({:ok, matched, remainder, match_count + 1}, fn
        expression, {:ok, matched, remainder, match_count} ->
          with {:ok, new_matched, new_remainder} <-
                 expression
                 |> triple_expression()
                 |> ShEx.TripleExpression.matches(remainder, graph, schema, association, shape_map)
          do
            {:cont, {:ok, new_matched, new_remainder, match_count}}
          else
            {:error, error} ->
              # TODO: Maybe we want to pass the error instead of just providing a min cardinality violation as reason? see the same for OneOf
              {:halt, {matched, remainder, match_count - 1}}
          end
        end)
    |> do_find_matches(expressions, max, graph, schema, association, shape_map)
  end

  defp do_find_matches(acc, _, _, _, _, _, _), do: acc


  defimpl ShEx.TripleExpression do
    def matches(each_of, triples, graph, schema, association, shape_map) do
      ShEx.EachOf.matches(each_of, triples, graph, schema, association, shape_map)
    end

    def predicates(each_of),
      do: ShEx.TripleExpression.Shared.predicates_of_group(each_of)

    def triple_constraints(each_of),
      do: ShEx.TripleExpression.Shared.triple_constraints_of_group(each_of)

    def required_arcs(each_of),
      do: ShEx.TripleExpression.Shared.required_arcs_of_group(each_of)
  end
end
