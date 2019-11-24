defmodule ShEx.ShapeAnd do
  @moduledoc false

  defstruct [
    # shapeExprLabel?
    :id,
    # [shapeExpr{2,}]
    :shape_exprs
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_and, graph, schema, association, state) do
      Enum.reduce(shape_and.shape_exprs, association, fn expression, association ->
        ShEx.ShapeExpression.satisfies(expression, graph, schema, association, state)
      end)
    end
  end

  defimpl ShEx.Operator do
    def children(shape_and) do
      Enum.map(shape_and.shape_exprs, fn expression ->
        if RDF.term?(expression) do
          {:shape_expression_label, expression}
        else
          expression
        end
      end)
    end

    def triple_expression_label_and_operands(shape_and), do: {nil, shape_and.shape_exprs}
  end
end
