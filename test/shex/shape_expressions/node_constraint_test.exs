defmodule ShEx.NodeConstraintTest do
  use ExUnit.Case
  doctest ShEx.NodeConstraint

  alias ShEx.NodeConstraint, as: NC
  alias ShEx.NodeConstraint.{StringFacets, NumericFacets}

  alias RDF.NS.XSD
  import RDF.Sigils

  @example_iri RDF.iri("http://example.com/")
  @example_string RDF.string("http://example.com/")
  @example_integer RDF.integer(42)

  describe "satisfies?/2" do
    test "iri node kind constraint" do
      [
        {@example_iri,     true},
        {RDF.bnode(),      false},
        {@example_string,  false},
        {@example_integer, false},
        {RDF.true,         false},
        {RDF.false,        false},
      ]
      |> Enum.each(fn {node, result} ->
           assert NC.satisfies?(%NC{node_kind: "iri"}, node) == result
         end)
    end

    test "bnode node kind constraint" do
      [
        {@example_iri,     false},
        {RDF.bnode(),      true},
        {@example_string,  false},
        {@example_integer, false},
        {RDF.true,         false},
        {RDF.false,        false},
      ]
      |> Enum.each(fn {node, expected_result} ->
           assert NC.satisfies?(%NC{node_kind: "bnode"}, node) == expected_result
         end)
    end

    test "literal node kind constraint" do
      [
        {@example_iri,     false},
        {RDF.bnode(),      false},
        {@example_string,  true},
        {@example_integer, true},
        {RDF.true,         true},
        {RDF.false,        true},
      ]
      |> Enum.each(fn {node, expected_result} ->
           assert NC.satisfies?(%NC{node_kind: "literal"}, node) == expected_result
         end)
    end

    test "nonliteral node kind constraint" do
      [
        {@example_iri,     true},
        {RDF.bnode(),      true},
        {@example_string,  false},
        {@example_integer, false},
        {RDF.true,         false},
        {RDF.false,        false},
      ]
      |> Enum.each(fn {node, expected_result} ->
           assert NC.satisfies?(%NC{node_kind: "nonliteral"}, node) == expected_result
         end)
    end

    test "datatype constraint" do
      [
        {@example_iri,     XSD.string,  false},
        {RDF.bnode(),      XSD.string,  false},
        {@example_string,  XSD.string,  true},
        {@example_integer, XSD.integer, true},
        {RDF.false,        XSD.boolean, true},
        {RDF.true,         XSD.boolean, true},
        {RDF.true,         XSD.string,  false},
        {@example_integer, XSD.string,  false},
        {@example_string,  XSD.integer, false},
        {~L"42",           XSD.integer, true},
      ]
      |> Enum.each(fn {node, datatype, expected_result} ->
           result = NC.satisfies?(%NC{datatype: datatype}, node)
           assert result == expected_result,
                  "node #{inspect node} does not match datatype #{inspect datatype} accordingly, expected #{inspect expected_result} but got #{inspect result}"
         end)
    end

    test "string facet constraint" do
      [
        {~L"foo",          %{length: 3}, true},
        {~L"foo",          %{minlength: 1}, true},
        {~L"foo",          %{minlength: 1, maxlength: 3}, true},
        {~L"foo",          %{minlength: 1, maxlength: 2}, false},
        {@example_integer, %{length: 2}, true},
        {RDF.false,        %{minlength: 2}, true},
        {RDF.true,         %{maxlength: 5}, true},
        {@example_iri,     %{minlength: 3}, true},
        {RDF.bnode("foo"), %{length: 3},  true},

        {RDF.bnode("foo"), %{pattern: "fo"}, true},
        {@example_iri, %{pattern: "example\.com"},  true},
        {@example_iri, %{pattern: "example.com", flags: "q"}, true},
        {@example_iri, %{pattern: "EXAMPLE.com", flags: "qi"}, true},
        {@example_iri, %{pattern: "foo"}, false},
      ]
      |> Enum.each(fn {node, xs_facets, expected_result} ->
           result = NC.satisfies?(%NC{string_facets: StringFacets.new(xs_facets)}, node)
           assert result == expected_result,
              "node #{inspect node} does not match string facets #{inspect xs_facets} accordingly, expected #{inspect expected_result} but got #{inspect result}"
         end)
    end

    test "numeric facet constraint" do
      [
        {@example_integer, %{mininclusive: 41}, true},
        {@example_integer, %{mininclusive: 42}, true},
        {@example_integer, %{mininclusive: 43}, false},

        {@example_integer, %{minexclusive: 42}, false},
        {@example_integer, %{minexclusive: 41}, true},

        {@example_integer, %{maxinclusive: 41}, false},
        {@example_integer, %{maxinclusive: 42}, true},
        {@example_integer, %{maxinclusive: 43}, true},

        {@example_integer, %{maxexclusive: 42}, false},
        {@example_integer, %{maxexclusive: 43}, true},

        {@example_integer, %{totaldigits: 2}, true},
        {@example_integer, %{totaldigits: 1}, true},
        {@example_integer, %{totaldigits: 3}, false},
        {@example_integer, %{fractiondigits: 0}, true},
        {@example_integer, %{fractiondigits: 3}, false},

        {@example_string,  %{mininclusive: 1}, nil},
        {RDF.false,        %{maxinclusive: 1}, nil},
        {RDF.true,         %{minexclusive: 1}, nil},
        {@example_iri,     %{maxexclusive: 1}, nil},
        {RDF.bnode("foo"), %{totaldigits: 1}, nil},
      ]
      |> Enum.each(fn {node, xs_facets, expected_result} ->
        result = NC.satisfies?(%NC{numeric_facets: NumericFacets.new(xs_facets)}, node)
        assert result == expected_result,
               "node #{inspect node} does not match numeric facets #{inspect xs_facets} accordingly, expected #{inspect expected_result} but got #{inspect result}"
      end)
    end

    test "values constraint" do
      [
        {@example_iri, [@example_iri], true},

        {~L"foo", [~L"foo"], true},
        {~L"foo", [~L"bar"], false},
        {~L"foo", [~L"foo"de], false},
        {@example_integer, [@example_integer], true},

        {~L"foo"en, [%{type: "Language", languageTag: "en"}], true},
        {~L"foo"en, [%{type: "Language", languageTag: "de"}], false},

        {@example_iri, [%{type: "IriStem", stem: @example_iri}], true},
        {RDF.iri("http://example.com/foo"), [%{type: "IriStem", stem: @example_iri}], true},
        {RDF.iri("http://example.org/foo"), [%{type: "IriStem", stem: @example_iri}], false},

        {~L"foo",   [%{type: "LiteralStem", stem: "foo"}], true},
        {~L"foo",   [%{type: "LiteralStem", stem: "fo"}], true},
        {~L"foo"en, [%{type: "LiteralStem", stem: "fo"}], true},
        {~L"foo",   [%{type: "LiteralStem", stem: "oo"}], false},
        {@example_integer, [%{type: "LiteralStem", stem: "4"}], true},
        {@example_integer, [%{type: "LiteralStem", stem: "2"}], false},

        {~L"foo"en, [%{type: "LanguageStem", stem: "en"}], true},
        {~L"foo"en, [%{type: "LanguageStem", stem: "de"}], false},
        {RDF.string("foo", language: "de-CH"), [%{type: "LanguageStem", stem: "de"}], true},
        {RDF.string("foo", language: "de-CH"), [%{type: "LanguageStem", stem: "de-ch"}], true},

        {@example_iri, [%{type: "IriStemRange", stem: @example_iri, exclusions: [RDF.iri("http://example.org/")]}], true},
        {@example_iri, [%{type: "IriStemRange", stem: @example_iri, exclusions: [@example_iri]}], false},
        {RDF.iri("http://example.com/foo"), [%{type: "IriStemRange", stem: @example_iri, exclusions: [%{type: "IriStem", stem: RDF.iri("http://example.com/foo-")}]}], true},
        {RDF.iri("http://example.com/foo-bar"), [%{type: "IriStemRange", stem: @example_iri, exclusions: [%{type: "IriStem", stem: RDF.iri("http://example.com/foo-")}]}], false},

        {~L"foo", [%{type: "LiteralStemRange", stem: "fo", exclusions: [~L"foo-bar"]}], true},
        {~L"foo-bar", [%{type: "LiteralStemRange", stem: "fo", exclusions: [~L"foo-bar"]}], false},
        {~L"foo", [%{type: "LiteralStemRange", stem: "fo", exclusions: [%{type: "LiteralStem", stem: "foo-"}]}], true},
        {~L"foo-bar", [%{type: "LiteralStemRange", stem: "fo", exclusions: [%{type: "LiteralStem", stem: "foo-"}]}], false},

        {@example_iri, [%{type: "IriStemRange", stem: %{type: "Wildcard"}, exclusions: [RDF.iri("http://example.org/")]}], true},
        {@example_iri, [%{type: "IriStemRange", stem: %{type: "Wildcard"}, exclusions: [@example_iri]}], false},
        {~L"foo", [%{type: "LiteralStemRange", stem: %{type: "Wildcard"}, exclusions: [~L"foo-bar"]}], true},
        {~L"foo-bar", [%{type: "LiteralStemRange", stem: %{type: "Wildcard"}, exclusions: [%{type: "LiteralStem", stem: "foo-"}]}], false},

      ]
      |> Enum.each(fn {node, value_set_values, expected_result} ->
           result = NC.satisfies?(%NC{values: value_set_values}, node)
           assert result == expected_result,
                  "node #{inspect node} does not match values constraint #{inspect value_set_values} accordingly, expected #{inspect expected_result} but got #{inspect result}"
         end)
    end
  end
end
