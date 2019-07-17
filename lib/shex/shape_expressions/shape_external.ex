defmodule ShEx.ShapeExternal do
  @moduledoc false

  defstruct [:id]

  defimpl ShEx.Operator do
    def children(_), do: []
    def triple_expression_label_and_operands(_), do: {nil, []}
  end
end
