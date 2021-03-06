defmodule ShEx.TestSuiteTest do
  use ShEx.TestSuite.Case

  describe "schemas" do
    TestSuite.test_cases("schemas")
    |> Enum.each(fn test_case ->
      [
        "FocusIRI2groupBnodeNested2groupIRIRef",
        "FocusIRI2EachBnodeNested2EachIRIRef"
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
          do: @tag(skip: "TODO: Retaining nested AND")
      end)

      if RDF.iri(SHT.Import) in TestSuite.test_case_traits(test_case),
        do: @tag(skip: "TODO: Imports")

      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        schema_test(test_case)
      end
    end)

    defp schema_test(test_case) do
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
  end

  describe "negativeSyntax" do
    # These tests violate the ShEx2 grammar
    TestSuite.test_cases("negativeSyntax")
    |> Enum.each(fn test_case ->
      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        negative_syntax_test(test_case)
      end
    end)

    defp negative_syntax_test(test_case) do
      assert {:error, _} =
               test_case
               |> ShEx.TestSuite.test_case_file(:shex)
               |> ShEx.TestSuite.file()
               |> File.read!()
               |> ShEx.ShExC.Decoder.decode()
    end
  end

  describe "negativeStructure" do
    TestSuite.test_cases("negativeStructure")
    |> Enum.each(fn test_case ->
      [
        "1focusRefANDSelfdot",
        "Cycle2Extra",
        "Cycle1Negation1",
        "Cycle1Negation2",
        "Cycle1Negation3",
        "Cycle2Negation",
        "TwoNegation",
        "TwoNegation2"
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
          do: @tag(skip: "TODO: ")
      end)

      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        negative_structure_test(test_case)
      end
    end)

    defp negative_structure_test(test_case) do
      assert {:error, _} =
               test_case
               |> ShEx.TestSuite.test_case_file(:shex)
               |> ShEx.TestSuite.file()
               |> File.read!()
               |> ShEx.ShExC.Decoder.decode()
    end
  end

  @validation_manifest ShEx.TestSuite.manifest_graph("validation")
  @validation_base_iri @validation_manifest.base_iri

  def validation_manifest, do: @validation_manifest

  describe "validation" do
    # These tests should raise errors when parsed, noting the rule about nested ValueAnd and ValueOr expressions.
    TestSuite.test_cases(@validation_manifest, suite_type: "validation")
    |> Enum.each(fn test_case ->
      #      [
      #        "3circRefS123-Icirc",
      #        "2RefS1-IS2",
      #        "2RefS1-Icirc",
      #        "2RefS2-IS1",
      #        "3circRefS1-IS23",
      #        "3circRefS1-IS2-IS3",
      #        "3circRefS3",
      #        "3circRefS3-IS12",
      #        "3circRefS123",
      #        "3circRefS123-Icirc",
      #        "3circRefS1-Icirc",
      #        "3circRefS1-IS2-IS3-IS3",
      #      ]
      if RDF.iri(SHT.Import) in TestSuite.test_case_traits(test_case),
        do: @tag(skip: "TODO: imports")

      #      [
      #        "shapeExtern",
      #      ]
      # Note that all tests with this trait have also the SemanticAction trait
      if RDF.iri(SHT.ExternalShape) in TestSuite.test_case_traits(test_case),
        do: @tag(skip: "TODO: external shapes")

      #      [
      #        "startCode1fail_abort",
      #        "startCode1startReffail_abort",
      #        "open3groupdotcloseCode1-p1p2p3",
      #        "1dotCode3fail_abort",
      #      ]
      if RDF.iri(SHT.SemanticAction) in TestSuite.test_case_traits(test_case),
        do: @tag(skip: "TODO: semantic actions")

      [
        "nPlus1",
        "PTstar-greedy-fail"
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
          do: @tag(skip: "TODO: greedy")
      end)

      [
        "1literalPattern_with_ascii_boundaries_fail",
        "1literalPattern_with_all_controls_fail"
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
          do: @tag(skip: "TODO: non-ascii character handling")
      end)

      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        validation_test(test_case)
      end
    end)

    defp validation_test(test_case) do
      test_case_action =
        validation_manifest()
        |> ShEx.TestSuite.test_case_action(test_case)

      schema_file =
        test_case_action
        |> RDF.Description.first(SHT.schema())
        |> ShEx.TestSuite.file()

      assert {:ok, schema} =
               schema_file
               |> File.read!()
               |> ShEx.ShExC.Decoder.decode(base: @validation_base_iri)

      shexj_schema_file = String.replace_trailing(schema_file, "shex", "json")

      if File.exists?(shexj_schema_file) do
        assert {:ok, shexj_schema} =
                 shexj_schema_file
                 |> File.read!()
                 |> ShEx.ShExJ.Decoder.decode(base: @validation_base_iri)

        # TODO: The schemas for these seem to be different ... see also "schemas" tests
        test_case_name = TestSuite.test_case_name(test_case)

        unless String.starts_with?(test_case_name, "FocusIRI2groupBnodeNested2groupIRIRef") or
                 String.starts_with?(test_case_name, "FocusIRI2EachBnodeNested2EachIRIRef") do
          assert shexj_schema == schema
        end
      end

      assert {:ok, graph} =
               test_case_action
               |> RDF.Description.first(SHT.data())
               |> ShEx.TestSuite.file()
               |> RDF.Turtle.read_file(base: @validation_base_iri)

      shape_map_file =
        test_case_action
        |> RDF.Description.first(SHT.map())
        |> ShEx.TestSuite.file()

      map =
        if shape_map_file do
          assert {:ok, shape_map} =
                   shape_map_file
                   |> File.read!()
                   |> ShEx.ShapeMap.from_json()

          shape_map
        else
          shape =
            if RDF.iri(SHT.Start) in TestSuite.test_case_traits(test_case),
              do: :start,
              else: RDF.Description.first(test_case_action, SHT.shape())

          ShEx.ShapeMap.new(%{RDF.Description.first(test_case_action, SHT.focus()) => shape})
        end

      result = RDF.Description.first(test_case, MF.result())

      shape_externs =
        test_case_action
        |> RDF.Description.first(SHT.shapeExterns())
        |> ShEx.TestSuite.file()

      external_shape =
        if shape_externs do
          assert {:ok, shape_externs_schema} =
                   shape_externs
                   |> File.read!()
                   |> ShEx.ShExC.Decoder.decode()
        end

      test_case
      |> ShEx.TestSuite.test_case_type()
      |> to_string()
      |> String.trim_leading("http://www.w3.org/ns/shacl/test-suite#")
      |> test_validation(graph, schema, map, result, external_shape)
    end

    defp test_validation(type, graph, schema, shape_map, nil, _external_shape) do
      assert %ShEx.ShapeMap{} = result = ShEx.validate(graph, schema, shape_map)

      case type do
        "ValidationTest" ->
          assert ShEx.ShapeMap.conformant?(result)

        "ValidationFailure" ->
          refute ShEx.ShapeMap.conformant?(result)
      end
    end

    defp test_validation(_type, graph, schema, shape_map, expected_result_file, _external_shape) do
      assert {:ok, expected_result} =
               expected_result_file
               |> ShEx.TestSuite.file()
               |> File.read!()
               |> ShEx.ShapeMap.from_json()

      assert %ShEx.ShapeMap{} = ShEx.validate(graph, schema, shape_map)
    end
  end
end
