defmodule ShEx.Utils do
  @moduledoc false

  def map(list, fun, options) do
    list
    |> Enum.reverse()
    |> Stream.map(fn element -> fun.(element, options) end)
    |> Enum.reduce({:ok, []}, fn
      {:ok, element}, {:ok, elements} ->
        {:ok, [element | elements]}

      {:ok, _}, {:error, errors} ->
        {:error, errors}

      {:error, errors}, {:ok, _} ->
        {:error, errors}

      {:error, new_errors}, {:error, previous_errors} ->
        {:error, List.wrap(new_errors) ++ List.wrap(previous_errors)}
    end)
  end

  def empty_to_nil({:ok, []}), do: {:ok, nil}
  def empty_to_nil(nil), do: {:ok, nil}
  def empty_to_nil(list), do: list

  def if_present(nil, _, _), do: {:ok, nil}
  def if_present(value, fun, options), do: fun.(value, options)

end
