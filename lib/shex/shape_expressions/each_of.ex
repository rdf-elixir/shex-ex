defmodule ShEx.EachOf do
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

  def matches(each_of, triples, graph, schema, association, state) do
    with {matched, remainder, match_count, violations} <-
           find_matches(triples, each_of, graph, schema, association, state),
         :ok <-
           check_cardinality(match_count,
             ShEx.TripleExpression.min_cardinality(each_of), each_of, violations)
    do
      {:ok, matched, remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, each_of, graph, schema, association, state) do
    do_find_matches({:ok, [], triples, 0, []},
      each_of.expressions, ShEx.TripleExpression.max_cardinality(each_of),
      graph, schema, association, state)
  end

  defp do_find_matches({:ok, matched, remainder, max, violations}, _, max, _, _, _, _),
     do: {matched, remainder, max, violations}

  defp do_find_matches({:ok, matched, remainder, match_count, violations},
         expressions, max, graph, schema, association, state) do
    expressions
    |> Enum.reduce_while({:ok, matched, remainder, match_count + 1, violations}, fn
        expression, {:ok, matched, remainder, match_count, violations} ->
          with {:ok, new_matched, new_remainder} <-
                 ShEx.TripleExpression.matches(
                   expression, remainder, graph, schema, association, state)
          do
            {:cont, {:ok, new_matched, new_remainder, match_count, violations}}
          else
            {:error, violation} ->
              {:halt, {matched, remainder, match_count - 1, violations ++ List.wrap(violation)}}
          end
        end)
    |> do_find_matches(expressions, max, graph, schema, association, state)
  end

  defp do_find_matches(acc, _, _, _, _, _, _), do: acc


  defimpl ShEx.TripleExpression do
    def matches(each_of, triples, graph, schema, association, state) do
      ShEx.EachOf.matches(each_of, triples, graph, schema, association, state)
    end

    def min_cardinality(each_of), do: ShEx.TripleExpression.Shared.min_cardinality(each_of)
    def max_cardinality(each_of), do: ShEx.TripleExpression.Shared.max_cardinality(each_of)

    def predicates(each_of, state),
      do: ShEx.TripleExpression.Shared.predicates_of_group(each_of, state)

    def triple_constraints(each_of, state),
      do: ShEx.TripleExpression.Shared.triple_constraints_of_group(each_of, state)

    def required_arcs(each_of, state),
      do: ShEx.TripleExpression.Shared.required_arcs_of_group(each_of, state)
  end

  defimpl ShEx.Operator do
    def triple_expression_label_and_operands(each_of),
      do: {each_of.id, each_of.expressions}
  end
end
