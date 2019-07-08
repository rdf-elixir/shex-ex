defmodule ShEx.ShapeAnd do
  @moduledoc false

  defstruct [
    :id,          # shapeExprLabel?
    :shape_exprs  # [shapeExpr{2,}]
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_and, graph, schema, association, state) do
      Enum.reduce(shape_and.shape_exprs, association, fn expression, association ->
        ShEx.ShapeExpression.satisfies(expression, graph, schema, association, state)
      end)
    end
  end

  defimpl ShEx.Operator do
    def triple_expression_label_and_operands(shape_and), do: {nil, shape_and.shape_exprs}
  end
end
