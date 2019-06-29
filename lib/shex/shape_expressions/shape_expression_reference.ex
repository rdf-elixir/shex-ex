defmodule ShEx.ShapeExpressionReference do
  def satisfies(expr_ref, graph, schema, association, state) do
    with {:ok, ref_stack} <-
            push_ref_stack(state.ref_stack, {expr_ref, association.node}),
          shape_expr when not is_nil(shape_expr) <-
            ShEx.Schema.shape_expr_with_id(schema, expr_ref) do
      ShEx.ShapeExpression.satisfies(shape_expr, graph, schema, association,
        %{state | ref_stack: ref_stack})
    else
      :circular_reference ->
        ShEx.ShapeMap.Association.conform(association)
      nil ->
        ShEx.ShapeMap.Association.violation(association,
          %ShEx.Violation.UnknownReference{expr_ref: expr_ref})
    end
  end

  defp push_ref_stack(stack, entry) do
    if entry in stack do
      :circular_reference
    else
      {:ok, [entry | stack]}
    end
  end
end

defimpl ShEx.ShapeExpression, for: RDF.IRI do
  def satisfies(expr_ref, graph, schema, association, state) do
    ShEx.ShapeExpressionReference.satisfies(expr_ref, graph, schema, association, state)
  end
end

defimpl ShEx.ShapeExpression, for: RDF.BlankNode do
  def satisfies(expr_ref, graph, schema, association, state) do
    ShEx.ShapeExpressionReference.satisfies(expr_ref, graph, schema, association, state)
  end
end

defimpl ShEx.Operator, for: RDF.IRI do
  def triple_expression_label_and_operands(_), do: {nil, []}
end

defimpl ShEx.Operator, for: RDF.BlankNode do
  def triple_expression_label_and_operands(_), do: {nil, []}
end
