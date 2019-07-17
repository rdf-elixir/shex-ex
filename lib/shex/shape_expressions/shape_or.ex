defmodule ShEx.ShapeOr do
  @moduledoc false

  defstruct [
    :id,          # shapeExprLabel?
    :shape_exprs  # [shapeExpr{2,}]
  ]

  defimpl ShEx.ShapeExpression do
    def satisfies(shape_or, graph, schema, association, state) do
      shape_or.shape_exprs
      |> Enum.reduce_while({[], []}, fn expression, {reasons, app_infos} ->
           ShEx.ShapeExpression.satisfies(expression, graph, schema, association, state)
           |> case do
                %{status: :conformant} ->
                  {:halt, :ok}
                %{reason: reason, app_info: app_info} ->
                  {:cont, {reasons ++ List.wrap(reason), [app_info | app_infos]}}
              end
         end)
      |> case do
           :ok ->
             ShEx.ShapeMap.Association.conform(association)

           {reasons, app_infos} ->
             ShEx.ShapeMap.Association.violation(association, reasons, app_infos)
         end
    end
  end

  defimpl ShEx.Operator do
    def children(shape_or) do
      Enum.map(shape_or.shape_exprs, fn expression ->
        if RDF.term?(expression) do
          {:shape_expression_label, expression}
        else
          expression
        end
      end)
    end

    def triple_expression_label_and_operands(shape_or), do: {nil, shape_or.shape_exprs}
  end
end
