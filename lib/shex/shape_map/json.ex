defmodule ShEx.ShapeMap.JSON do

  def decode(content, options \\ []) do
    with {:ok, json_objects} <- parse_json(content, options) do
      {:ok, ShEx.ShapeMap.new(json_objects)}
    end
  end

  defp parse_json(content, opts \\ []) do
    Jason.decode(content, opts)
  end
end
