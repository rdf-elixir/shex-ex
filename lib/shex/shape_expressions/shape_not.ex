defmodule ShEx.ShapeNot do
  @moduledoc false

  defstruct [
    # shapeExprLabel?
    :id,
    # shapeExpr
    :shape_expr
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_not, graph, schema, association, state) do
      if match?(
           %{status: :nonconformant},
           ShEx.ShapeExpression.satisfies(shape_not.shape_expr, graph, schema, association, state)
         ) do
        ShEx.ShapeMap.Association.conform(association)
      else
        ShEx.ShapeMap.Association.violation(
          association,
          %ShEx.Violation.NegationMatch{shape_not: shape_not}
        )
      end
    end
  end

  defimpl ShEx.Operator do
    def children(shape_not) do
      if RDF.term?(shape_not.shape_expr) do
        {:shape_expression_label, shape_not.shape_expr}
      else
        shape_not.shape_expr
      end
      |> List.wrap()
    end

    def triple_expression_label_and_operands(shape_not), do: {nil, [shape_not.shape_expr]}
  end
end
