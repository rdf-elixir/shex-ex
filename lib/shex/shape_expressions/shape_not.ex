defmodule ShEx.ShapeNot do
  defstruct [
    :id,         # shapeExprLabel?
    :shape_expr  # shapeExpr
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_not, graph, schema, association, state) do
      if match?(%{status: :nonconformant},
           ShEx.ShapeExpression.satisfies(shape_not.shape_expr, graph, schema, association, state)) do
        ShEx.ShapeMap.Association.conform(association)
      else
        ShEx.ShapeMap.Association.violation(association,
          %ShEx.Violation.NegationMatch{shape_not: shape_not})
      end
    end
  end

  defimpl ShEx.Operator do
    def triple_expression_label_and_operands(shape_not), do: {nil, [shape_not.shape_expr]}
  end
end
