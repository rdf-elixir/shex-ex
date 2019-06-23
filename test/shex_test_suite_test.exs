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

      if RDF.iri(SHT.Import) in TestSuite.test_case_traits(test_case),
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


  @validation_manifest ShEx.TestSuite.manifest_graph("validation")
  @validation_base_iri "https://raw.githubusercontent.com/shexSpec/shexTest/master/validation/manifest" # TODO: This should be the @validation_manifest.base_iri

  def validation_manifest, do: @validation_manifest

  describe "validation" do
    # These tests should raise errors when parsed, noting the rule about nested ValueAnd and ValueOr expressions.
    TestSuite.test_cases(@validation_manifest, suite_type: "validation")
    |> Enum.each(fn test_case ->

      [
        "1literalPattern_with_ascii_boundaries_fail",
        "1literalPattern_with_all_controls_fail",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: non-ascii character handling"
      end)

      [
        "startRefIRIREF_pass-others_lexicallyEarlier",
        "startRefIRIREF_pass-noOthers",
        "startRefIRIREF_fail-missing",
        "startRefbnode_fail-missing",
        "startRefbnode_pass-noOthers",
      ]
      if RDF.iri(SHT.Start) in TestSuite.test_case_traits(test_case),
         do: @tag skip: "TODO: start node (protocol ShEx.ShapeExpression not implemented for nil)"

#      [
#        "2OneInclude1_pass",
#      ]
      if RDF.iri(SHT.Include) in TestSuite.test_case_traits(test_case),
        do: @tag skip: "TODO: include"

      [
        "node_kind_example",
        "recursion_example",
        "dependent_shape",
        "1dot_fail-empty-err",
        "2RefS1-IS2",
        "2RefS1-Icirc",
        "2RefS2-IS1",
        "3circRefS1-IS23",
        "3circRefS1-IS2-IS3",
        "3circRefS3",
        "3circRefS3-IS12",
        "3circRefS123",
        "3circRefS123-Icirc",
        "3circRefS1-Icirc",
        "3circRefS1-IS2-IS3-IS3",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: loading query and/or result shape map"
      end)

#      [
#        "3circRefS123-Icirc",
#      ]
      if RDF.iri(SHT.Import) in TestSuite.test_case_traits(test_case),
        do: @tag skip: "TODO: imports"

#      [
#        "shapeExtern",
#      ]
      # Note that all tests with this trait have also the SemanticAction trait
      if RDF.iri(SHT.ExternalShape) in TestSuite.test_case_traits(test_case),
        do: @tag skip: "TODO: external shapes"

#      [
#        "startCode1fail_abort",
#        "startCode1startReffail_abort",
#        "open3groupdotcloseCode1-p1p2p3",
#        "1dotCode3fail_abort",
#      ]
      if RDF.iri(SHT.SemanticAction) in TestSuite.test_case_traits(test_case),
         do: @tag skip: "TODO: semantic actions"

      [
        "1literalTotaldigits_pass-byte-short",
        "1literalTotaldigits_pass-byte-equal",
        "1literalTotaldigits_fail-byte-long",
        "1literalTotaldigits_fail-float-equal",
        "1literalFractiondigits_fail-float-equal",
        "byte-n129_fail",
        "byte-128_fail",
        "byte-empty_fail",
        "short-n32769_fail",
        "short-32768_fail",
        "float-pINF_fail",
        "float-empty_fail",
        "unsignedLong-n1_fail",
        "unsignedByte-n1_fail",
        "unsignedByte-256_fail",
        "unsignedShort-65536_fail",
        "unsignedShort-n1_fail",
        "unsignedInt-n1_fail",
        "positiveInteger-n1_fail",
        "positiveInteger-0_fail",
        "nonNegativeInteger-n1_fail",
        "negativeInteger-0_fail",
        "negativeInteger-1_fail",
        "negativeInteger-n0_fail",
        "negativeInteger-p0_fail",
        "nonPositiveInteger-1a_fail",
        "nonPositiveInteger-p1_fail",
        "nonPositiveInteger-1_fail",
        "nonPositiveInteger-a1_fail",
      ]
      |> Enum.each(fn test_subject ->
        if test_case |> TestSuite.test_case_name() |> String.starts_with?(test_subject),
           do: @tag skip: "TODO: unsupported datatype"
      end)

      @tag test_case: test_case
      test TestSuite.test_case_title(test_case), %{test_case: test_case} do
        test_case_action =
          validation_manifest()
          |> ShEx.TestSuite.test_case_action(test_case)

        # TODO: Test this also with the schema from the corresponding ShExJ file if present
        assert {:ok, schema} =
                 test_case_action
                 |> RDF.Description.first(SHT.schema)
                 |> ShEx.TestSuite.file()
                 |> File.read!()
                 |> ShEx.ShExC.Decoder.decode(base: @validation_base_iri)

        assert {:ok, graph} =
                 test_case_action
                 |> RDF.Description.first(SHT.data)
                 |> ShEx.TestSuite.file()
                 |> RDF.Turtle.read_file(base: @validation_base_iri)

        shape_map_file =
          test_case_action
          |> RDF.Description.first(SHT.map)
          |> ShEx.TestSuite.file()

        map =
          if shape_map_file do
            # TODO: decode query ShapeMap from JSON
          else
            ShEx.ShapeMap.new(%{
              RDF.Description.first(test_case_action, SHT.focus) =>
              RDF.Description.first(test_case_action, SHT.shape)
            })
          end

        # TODO: decode result ShapeMap from JSON
        result = nil

        # TODO: sht:shapeExterns <../schemas/shapeExtern.shextern>
        shape_externs =
          test_case_action
          |> RDF.Description.first(SHT.shapeExterns)
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
    end)


    defp test_validation(type, graph, schema, shape_map, nil, _external_shape) do
      assert %ShEx.ShapeMap{} = result = ShEx.validate(graph, schema, shape_map)
      case type do
        "ValidationTest"    -> assert ShEx.ShapeMap.conformant?(result)
        "ValidationFailure" -> refute ShEx.ShapeMap.conformant?(result)
      end
    end

    defp test_validation(type, graph, schema, shape_map, expected_result, _external_shape) do
      assert false, "Result parser missing" # TODO
    end
  end
end
