defmodule ShEx.ShapeNot do
  defstruct [
    :id,         # tripleExprLabel?
    :shape_expr  # shapeExpr
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_not, graph, schema, association, shape_map) do
      if match?(%{status: :nonconformant},
           ShEx.ShapeExpression.satisfies(shape_not.shape_expr, graph, schema, association, shape_map)) do
        ShEx.ShapeMap.Association.conform(association)
      else
        ShEx.ShapeMap.Association.violation(association,
          %ShEx.Violation.NegationMatch{shape_not: shape_not})
      end
    end
  end
end
