defmodule ShEx.TestSuite.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      ExUnit.Case.register_attribute __ENV__, :test_case

      alias ShEx.TestSuite
      alias TestSuite.NS.{MF, SX, SHT}

      import ShEx.TestSuite.Case
    end
  end
end
