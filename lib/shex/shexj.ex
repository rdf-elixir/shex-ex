defmodule ShEx.ShExJ do
  defdelegate decode(content, opts \\ []), to: ShEx.ShExJ.Decoder

  def decode!(content, opts \\ []) do
    with {:ok, schema} <- decode(content, opts) do
      schema
    else
      {:error, error} ->
        raise error
    end
  end
end
