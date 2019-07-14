defmodule ShEx do
  alias ShEx.{Schema, ShapeMap}

  def validate(data, schema, shape_map, opts \\ [])

  def validate(data, %Schema{} = schema, %ShapeMap{} = shape_map, opts) do
    Schema.validate(schema, data, shape_map, opts)
  end

  def validate(data, %Schema{} = schema, shape_map, opts) do
    validate(data, schema, shape_map(shape_map), opts)
  end

  defdelegate shape_map(),        to: ShapeMap, as: :new
  defdelegate shape_map(mapping), to: ShapeMap, as: :new
end
