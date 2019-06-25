defmodule ShEx.ExpressionReference do
  def satisfies(expr_ref, graph, schema, association, shape_map, ref_stack) do
    with {:ok, ref_stack} <-
            push_ref_stack(ref_stack, {expr_ref, association.node}),
          shape_expr when not is_nil(shape_expr) <-
            ShEx.Schema.shape_expr_with_id(schema, expr_ref) do
      ShEx.ShapeExpression.satisfies(shape_expr, graph, schema, association, shape_map, ref_stack)
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
  def satisfies(expr_ref, graph, schema, association, shape_map, ref_stack) do
    ShEx.ExpressionReference.satisfies(expr_ref, graph, schema, association, shape_map, ref_stack)
  end
end

defimpl ShEx.ShapeExpression, for: RDF.BlankNode do
  def satisfies(expr_ref, graph, schema, association, shape_map, ref_stack) do
    ShEx.ExpressionReference.satisfies(expr_ref, graph, schema, association, shape_map, ref_stack)
  end
end
