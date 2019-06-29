defmodule ShEx.TripleConstraint do
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

  alias RDF.{IRI, BlankNode, Literal}

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
    with {matched, mismatched, remainder} <-
           find_matches(triples, triple_constraint, graph, schema, association, state),
         :ok <-
           check_cardinality(length(matched), triple_constraint.min || 1, triple_constraint)
    do
      {:ok, matched, mismatched ++ remainder}
    else
      violation ->
        {:error, violation}
    end
  end

  defp find_matches(triples, triple_constraint, graph, schema, association, state) do
    do_find_matches(
      {[], [], triples},
      triple_constraint.value_expr,
      triple_constraint.predicate,
      triple_constraint.inverse,
      triple_constraint.max || 1,
      {graph, schema, association, state}
    )
  end

  defp do_find_matches(acc, value_expr, predicate, inverse, max, match_context)

  defp do_find_matches({matched, mismatched, []}, _, _, _, _, _),
    do: {matched, mismatched, []}

  defp do_find_matches({matched, _, _} = acc, _, _, _, max, _)
    when length(matched) == max, do: acc

  defp do_find_matches(
         {matched, mismatched, [{subject, predicate, object} = statement | remainder]},
         nil, predicate, inverse, max, match_context) do
    {[statement | matched], mismatched, remainder}
    |> do_find_matches(nil, predicate, inverse, max, match_context)
  end

  defp do_find_matches(
         {matched, mismatched, [{subject, predicate, object} = statement | remainder]},
         value_expr, predicate, inverse, max,
         {graph, schema, association, state} = match_context) do
      value = if inverse, do: subject, else: object

      with %{status: :conformant} <-
             ShEx.ShapeExpression.satisfies(
               value_expr,
               graph,
               schema,
               ShEx.ShapeMap.Association.new(value, value_expr),
               state)
      do
        {[statement | matched], mismatched, remainder}
      else
        _ ->
          {matched, [statement | mismatched], remainder}
      end
      |> do_find_matches(value_expr, predicate, inverse, max, match_context)
  end

  defp do_find_matches({matched, mismatched, [statement | remainder]},
         value_expr, predicate, inverse, max, match_context) do
    {matched, [statement | mismatched], remainder}
    |> do_find_matches(value_expr, predicate, inverse, max, match_context)
  end


  defimpl ShEx.TripleExpression do
    def matches(triple_constraint, triples, graph, schema, association, state) do
      ShEx.TripleConstraint.matches(triple_constraint, triples, graph, schema, association, state)
    end

    def predicates(%ShEx.TripleConstraint{predicate: predicate}, _), do: [predicate]

    def triple_constraints(triple_constraint, _), do: [triple_constraint]

    def required_arcs(%ShEx.TripleConstraint{inverse: true}, _), do: {:ok, :arcs_in}
    def required_arcs(_, _), do: {:ok, :arcs_out}
  end

  defimpl ShEx.Operator do
    def triple_expression_label_and_operands(triple_constraint),
      do: {triple_constraint.id, List.wrap(triple_constraint.value_expr)}
  end
end
