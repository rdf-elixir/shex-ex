defmodule ShEx.ShExJ do
  @moduledoc """
  Functions for working with the ShExJ format.
  """

  @doc """
  Reads a `ShEx.Schema` from a string with a ShExJ schema definition.

  Returns an `ok` resp. `error` tuple.
  """
  defdelegate decode(content, opts \\ []), to: ShEx.ShExJ.Decoder

  @doc """
  Reads a `ShEx.Schema` from a string with a ShExJ schema definition and fails in the error case.

  Same as `decode/2` but returns the schema directly (not in an `ok` tuple).
  """
  def decode!(content, opts \\ []) do
    with {:ok, schema} <- decode(content, opts) do
      schema
    else
      {:error, error} ->
        raise error
    end
  end
end
