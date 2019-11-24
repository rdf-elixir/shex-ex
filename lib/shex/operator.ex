defmodule ShEx.Operator.Shared do
  @moduledoc false

  def check(operator, fun) do
    with :ok <- fun.(operator) do
      operator
      |> ShEx.Operator.children()
      |> Enum.reduce_while(:ok, fn
        child, _ when is_tuple(child) ->
          case fun.(child) do
            :ok -> {:cont, :ok}
            fail -> {:halt, fail}
          end

        child, _ ->
          case ShEx.Operator.check(child, fun) do
            :ok -> {:cont, :ok}
            fail -> {:halt, fail}
          end
      end)
    end
  end
end

defprotocol ShEx.Operator do
  @moduledoc false

  def children(operator)

  def triple_expression_label_and_operands(operator)

  defdelegate check(operator, fun), to: ShEx.Operator.Shared
end
