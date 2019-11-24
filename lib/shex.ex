defmodule ShEx do
  @moduledoc """
  An implementation of the [ShEx](http://www.w3.org/TR/sparql11-overview/) standard for Elixir.

  For a general introduction you may refer to the guides on the [homepage](https://rdf-elixir.dev).
  """

  alias ShEx.{Schema, ShapeMap}

  @doc """
  Validates that a `RDF.Data` structure conforms to a `ShEx.Schema` according to a `ShEx.ShapeMap`.

  If the ShapeMap is not given as `ShEx.ShapeMap` the given argument will be tried
  to converted to one with `ShEx.shape_map/1`.
  """
  def validate(data, schema, shape_map, opts \\ [])

  def validate(data, %Schema{} = schema, %ShapeMap{} = shape_map, opts) do
    Schema.validate(schema, data, shape_map, opts)
  end

  def validate(data, %Schema{} = schema, shape_map, opts) do
    validate(data, schema, shape_map(shape_map), opts)
  end

  defdelegate shape_map(), to: ShapeMap, as: :new
  defdelegate shape_map(mapping), to: ShapeMap, as: :new
end
