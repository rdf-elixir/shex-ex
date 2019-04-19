defmodule ShExTest do
  use ExUnit.Case
  doctest ShEx

  test "greets the world" do
    assert ShEx.hello() == :world
  end
end
