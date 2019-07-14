defmodule ShEx.ShExC do
  @moduledoc """
  Functions for working with the ShExC format.

  ShExC is the standard-format for the definition of ShEx schemas.

  See <http://shex.io/shex-primer/> for an introduction.
  """

  @doc """
  Reads a `ShEx.Schema` from a string with a ShExC schema definition.

  Returns an `ok` resp. `error` tuple.

  ### Options

  - `base`: the base IRI to be used for relative IRIs in the schema definition

  """
  defdelegate decode(content, opts \\ []), to: ShEx.ShExC.Decoder

  @doc """
  Reads a `ShEx.Schema` from a string with a ShExC schema definition and fails in the error case.

  Same as `decode/2` but returns the schema directly (not in an `ok` tuple).
  """
  def decode!(content, opts \\ []) do
    case decode(content, opts) do
      {:ok, schema}   -> schema
      {:error, error} -> raise error
    end
  end
end
