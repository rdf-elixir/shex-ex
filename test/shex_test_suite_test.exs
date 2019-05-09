defmodule ShEx.TestSuiteTest do
  use ShEx.TestSuite.Case

  describe "schemas" do
    TestSuite.test_cases("schemas")
    |> Enum.each(fn test_case ->
      [
        "_all",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO:"
      end)

      [
        "1literalPatternDollar",
        "1literalPattern_with_all_meta",
        "1literalPattern_with_all_punctuation",
        "1literalPattern_with_REGEXP_escapes",
        "1literalPattern_with_REGEXP_escapes_bare",
        "1literalPattern_with_ascii_boundaries",
        "1literalCarrotPatternDollar",
        "1focusPattern-dot",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: Regex escaping issues"
      end)

      [
        "1dotCodeWithEscapes1",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: Code escaping issues"
      end)

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
end
