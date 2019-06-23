defmodule ShEx do
  @moduledoc """
  TODO: Documentation for ShEx.
  """

  @doc """

  """
  def validate(data, schema, shape_map, opts \\ []) do
    ShEx.Schema.validate(schema, data, shape_map, opts)
  end

end
