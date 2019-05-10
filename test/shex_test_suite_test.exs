defmodule ShEx.TestSuiteTest do
  use ShEx.TestSuite.Case

  describe "schemas" do
    TestSuite.test_cases("schemas")
    |> Enum.each(fn test_case ->
      [
        "FocusIRI2groupBnodeNested2groupIRIRef",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: Retaining nested AND"
      end)

      if TestSuite.test_case_trait(test_case) == RDF.IRI.to_string(SHT.Import),
         do: @tag skip: "TODO: Imports"

      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        assert {:ok, shexj_schema} =
                 test_case
                 |> ShEx.TestSuite.test_case_file(:json)
                 |> ShEx.TestSuite.file()
                 |> File.read!()
                 |> ShEx.ShExJ.Decoder.decode()

        assert {:ok, shexc_schema} =
                 test_case
                 |> ShEx.TestSuite.test_case_file(:shex)
                 |> ShEx.TestSuite.file()
                 |> File.read!()
                 |> ShEx.ShExC.Decoder.decode()

        assert shexc_schema == shexj_schema
      end
    end)
  end

  describe "negativeSyntax" do
    # These tests violate the ShEx2 grammar
    TestSuite.test_cases("negativeSyntax")
    |> Enum.each(fn test_case ->
      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        assert {:error, _} =
                 test_case
                 |> ShEx.TestSuite.test_case_file(:shex)
                 |> ShEx.TestSuite.file()
                 |> File.read!()
                 |> ShEx.ShExC.Decoder.decode()
      end
    end)
  end
end
