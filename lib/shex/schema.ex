defmodule ShEx.Schema do
  @moduledoc """
  A ShEx schema is a collection of `ShEx.ShapeExpression` that prescribes conditions that RDF data graphs must meet in order to be considered "conformant".
  """

  defstruct [
    :shapes,     # [shapeExpr+]?
    :start,      # shapeExpr?
    :imports,    # [IRI+]?
    :start_acts  # [SemAct+]?
  ]

  alias ShEx.{ShapeMap, ShapeExpression}

  def new(shapes, start \\ nil, imports \\ nil, start_acts \\ nil) do
    %ShEx.Schema{
      shapes: shapes |> List.wrap() |> Map.new(fn shape -> {shape.id, shape} end),
      start: start,
      imports: imports,
      start_acts: start_acts
    }
  end

  def validate(schema, data, shape_map, opts \\ [])

  def validate(schema, data, %ShapeMap{type: :query} = shape_map, opts) do
    validate(schema, data, ShapeMap.to_fixed(shape_map), opts)
  end

  def validate(schema, data, %ShapeMap{type: :fixed} = shape_map, opts) do
    start = start_shape_expr(schema)
    shape_map
    |> ShapeMap.associations()
    |> Enum.reduce(%ShapeMap{type: :result}, fn association, result_shape_map ->
         result_shape_map
         |> ShapeMap.add(
              schema
              |> shape_expr(association.shape, start)
              |> ShapeExpression.satisfies(data, schema, association, shape_map, [])
            )
       end)
  end

  def shape_expr_with_id(schema, shape_label) do
    Map.get(schema.shapes, shape_label)
  end

  defp start_shape_expr(schema) do
    if RDF.resource?(schema.start) do
      shape_expr_with_id(schema, schema.start)
    else
      schema.start
    end
  end

  defp shape_expr(_, :start, start_expr), do: start_expr
  defp shape_expr(schema, shape_label, _), do: shape_expr_with_id(schema, shape_label)
end
