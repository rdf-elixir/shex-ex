defmodule ShEx.ShExC do
  defdelegate decode(content, opts \\ []), to: ShEx.ShExC.Decoder

  def decode!(content, opts \\ []) do
    with {:ok, schema} <- decode(content, opts) do
      schema
    else
      {:error, error} ->
        raise error
    end
  end
end
