defmodule ShEx.ShapeAnd do
  defstruct [
    :id,          # tripleExprLabel?
    :shape_exprs  # [shapeExpr{2,}]
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_and, graph, schema, association, shape_map) do
      Enum.reduce(shape_and.shape_exprs, association, fn expression, association ->
        ShEx.ShapeExpression.satisfies(expression, graph, schema, association, shape_map)
      end)
    end
  end
end
